#!/usr/bin/env python3
"""Preserve physical port aliases without bypassing finite wire resistance."""
import itertools
import json
import math
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys

TESTDIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TESTDIR.parent.parent / 'common'))
from spicenet import effective_resistance, parse_value, read_lines

magic, pdk, work, tech = sys.argv[1:]
work = Path(work)
rc = str(Path(pdk) / 'sky130A/libs.tech/magic/sky130A.magicrc')
width = 50
left, mid, right = 25, 100000, 199975


class Union:
    def __init__(self):
        self.parent = {}
    def find(self, n):
        self.parent.setdefault(n, n)
        if self.parent[n] != n:
            self.parent[n] = self.find(self.parent[n])
        return self.parent[n]
    def join(self, a, b):
        self.parent[self.find(b)] = self.find(a)


def pin(name, x, layer='metal1', port=True):
    return name, x, layer, port


cases = {
    'distinct': [pin('A', left), pin('B', mid), pin('C', right)],
    'coincident': [pin('A', left), pin('B', mid), pin('D', mid), pin('C', right)],
    'triple': [pin('A', left), pin('B', mid), pin('D', mid), pin('E', mid), pin('C', right)],
    'repeated_end': [pin('A', left), pin('B', right), pin('A', right)],
    'repeated_mid': [pin('A', left), pin('B', mid), pin('A', mid), pin('C', right)],
    'alias_chain': [pin('A', left), pin('B', mid), pin('A', mid),
                    pin('D', 150000), pin('B', 150000), pin('C', right)],
    'near_not_coincident': [pin('A', left), pin('D', right-50), pin('B', right)],
    'annotation': [pin('A', left), pin('B', right), pin('A', right-50, port=False)],
    'two_planes': [pin('A', left), pin('B', mid), pin('D', mid), pin('C', right),
                   pin('U', left, 'metal2'), pin('V', mid, 'metal2'),
                   pin('W', mid, 'metal2'), pin('Z', right, 'metal2')],
}


def native(path, resfile=None, policy=None, required=()):
    union, resistors, active, ports, caps = Union(), [], set(), set(), 0.0
    for row in read_lines(path):
        key = row[0].lower()
        if key == '.subckt':
            ports.update(row[2:])
        elif key[0] in 'rcv':
            a, b = row[1:3]
            active.update([a,b])
            value = parse_value(row[3])
            assert math.isfinite(value) and value >= 0, (path, row)
            if key[0] == 'c':
                caps += value
            elif key[0] == 'v':
                assert value == 0
                union.join(a,b)
            elif value == 0:
                union.join(a,b)
            else:
                resistors.append((key,[a,b],value))
        elif not key.startswith('.'):
            raise RuntimeError('Unexpected device: '+str(row))
    assert not (ports-active), 'Exported but unconnected ports: '+str(ports-active)
    if policy in ['resistor','voltage']:
        assert set(required) <= ports, ('Missing exported ports',set(required)-ports)
    elif policy == 'none':
        # short none may remove a coincident alias from the interface.  Use
        # only explicit geometry-derived .res.ext aliases, and only for a
        # name absent from both the interface and every native element.
        # Never "repair" an exported floating port or consume .ext equivs.
        for line in resfile.read_text().splitlines():
            row=shlex.split(line)
            if row and row[0]=='equiv':
                a,b=row[1:3]
                if a not in (active|ports) or b not in (active|ports):
                    union.join(a,b)
    resistors=[(n,[union.find(a),union.find(b)],r) for n,(a,b),r in resistors]
    return union,resistors,caps


def reference(pins, sheets):
    # An independent straight-wire model: R = Rsheet * length / width.
    # Coincident contacts and repeated external port names are ideal ties.
    union, edges, locations = Union(), [], {}
    for name,x,layer,is_port in pins:
        if not is_port:
            continue
        node=layer+':'+str(x)
        union.join(name,node)
        locations.setdefault(layer,set()).add(x)
    for layer,coords in locations.items():
        for a,b in zip(sorted(coords),sorted(coords)[1:]):
            edges.append(('r',[union.find(layer+':'+str(a)),union.find(layer+':'+str(b))],
                          sheets[layer]*(b-a)/width))
    return union,edges


try:
    text=Path(tech).read_text()
    sheets={layer: float(re.search(r'^\s*resist\s+\(allm'+n+r'\)/metal'+n+r'\s+(\S+)',
                          text,re.M)[1])/1000 for layer,n in [('metal1','1'),('metal2','2')]}
    records=[]
    failures=[]
    for case,pins in cases.items():
        names=list(dict.fromkeys(p[0] for p in pins if p[3]))
        expected_union,expected_edges=reference(pins,sheets)
        for reverse,simplify,policy in itertools.product([False,True],['on','off'],['none','resistor','voltage']):
            tag=case+('_reverse' if reverse else '')+'_'+simplify+'_'+policy
            directory=work/tag
            directory.mkdir()
            layers=list(dict.fromkeys(p[2] for p in pins))
            lines=['magic','tech sky130A','timestamp 0']
            for layer in layers:
                lines += ['<< '+layer+' >>','rect 0 0 200000 50']
            lines += ['<< labels >>']
            for name,x,layer,is_port in (list(reversed(pins)) if reverse else pins):
                lines.append(f'rlabel {layer} {x} 25 {x} 25 0 {name}')
                if is_port:
                    lines.append('port %d nsew' % (names.index(name)+1))
            lines += ['<< end >>']
            (directory/'wire.mag').write_text('\n'.join(lines)+'\n')
            tcl=('crashbackups stop\ndrc off\nload wire\nextract no unique\n'
                 'extract do capacitance\nextract do coupling\nextract no resistance\n'
                 'extract all\next2spice lvs\next2spice cthresh 0\next2spice rthresh 0\n'
                 'ext2spice subcircuit top on\next2spice short resistor\n'
                 'ext2spice extresist off\next2spice -o c_only.spice\n'
                 'extresist threshold 0\nextresist mindelay 0\nextresist minres 0\n'
                 'extresist prune 0\nextresist simplify '+simplify+'\n'
                 'extract do resistance\nextract all\next2spice extresist on\n'
                 'ext2spice short '+policy+'\next2spice -o wire.spice\n'
                 'puts ALIASES_DONE\nquit -noprompt\n')
            (directory/'extract.tcl').write_text(tcl)
            command=shlex.split(magic)+['-dnull','-noconsole','-rcfile',rc,'extract.tcl']
            if os.environ.get('VALGRIND'):
                command=['valgrind','--trace-children=yes',
                         '--log-file='+str(work/('valgrind.'+tag+'.%p.log'))]+command
            with (directory/'magic.log').open('w') as log:
                proc=subprocess.run(command,cwd=directory,stdout=log,stderr=subprocess.STDOUT,timeout=90)
            log=(directory/'magic.log').read_text()
            record=dict(case=case,reverse=reverse,simplify=simplify,policy=policy)
            try:
                assert proc.returncode==0 and 'ALIASES_DONE' in log, 'Incomplete extraction'
                assert not any(s in log for s in ["Couldn't find wire",'Error in extracting','Orphaned node']), log
                union,edges,cap_rc=native(directory/'wire.spice',directory/'wire.res.ext',policy,names)
                _,_,cap_c=native(directory/'c_only.spice')
                # The native SPICE writer rounds each capacitor separately.
                assert math.isclose(cap_rc,cap_c,rel_tol=5e-5,abs_tol=1e-18), (cap_rc,cap_c)
                measured={}
                for a,b in itertools.combinations(names,2):
                    actual=effective_resistance(edges,union.find(a),union.find(b))
                    expected=effective_resistance(expected_edges,expected_union.find(a),expected_union.find(b))
                    measured[a+'-'+b]=actual
                    if expected is None:
                        assert actual is None, ('Different conductors shorted',a,b,actual)
                    else:
                        assert actual is not None and math.isclose(actual,expected,rel_tol=2e-5,abs_tol=.002), (a,b,actual,expected)
                record.update(passed=True,r_ohm=measured,cap_rc_fF=cap_rc*1e15,cap_c_fF=cap_c*1e15)
            except Exception as error:
                record.update(passed=False,error=str(error))
                failures.append(tag+': '+str(error))
            records.append(record)
        print('  '+case+': checked 12 order/simplify/short combinations',flush=True)
    (work/'results.json').write_text(json.dumps(records,indent=2)+'\n')
    if failures:
        raise RuntimeError('\n'.join(failures))
    print('  Checked 108 extraction combinations, all port-pair resistances, isolation and capacitance conservation')
except Exception as error:
    print('FAIL:',error)
    sys.exit(1)
