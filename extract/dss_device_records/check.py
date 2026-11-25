#!/usr/bin/env python3
"""Two device records for one model, told apart by their terminal types.

The layout has a one-sided DSS nFET (salicide block, ndiffres, on one side
of the gate and plain ndiff on the other) and a two-sided one (ndiffres on
both sides).  Each tech file variant has two records for nfet_03v3_dss, one
for each kind of device, in different orders and with the one-sided record
written both ways round.  Every variant must extract both devices with
their own record and parameters.
"""
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys

TESTDIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TESTDIR.parent.parent / 'common'))
from spicenet import parse_value, read_lines

magic, work, tech = sys.argv[1:]
work = Path(work)

PARAMS = 'l=l w=w a1=as p1=ps a2=ad p2=pd'
TWO = ('device msubcircuit nfet_03v3_dss nfet ndiffres ndiffres allpsub error '
       + PARAMS + ' l1=s_sab l2=d_sab')
ONE = ('device msubcircuit nfet_03v3_dss nfet *ndiff ndiffres allpsub error '
       + PARAMS + ' l1=s_sab*0 l2=d_sab')
ONE_SWAPPED = ('device msubcircuit nfet_03v3_dss nfet ndiffres *ndiff allpsub error '
               + PARAMS + ' l1=s_sab l2=d_sab*0')
VARIANTS = {
    'two_first': [TWO, ONE],
    'one_first': [ONE, TWO],
    'two_first_swapped': [TWO, ONE_SWAPPED],
    'one_first_swapped': [ONE_SWAPPED, TWO],
}

# Layout geometry (internal units):  both gates are 14 long, and the
# ndiffres (salicide block) regions are 9 wide.  The one-sided device has
# ndiffres between the gate and S1, and plain ndiff between the gate and D1.
GATE_LEN, SAB_LEN = 14, 9


def make_tech(records, path):
    text = Path(tech).read_text()
    # The PDK has a single record for the two-sided device.
    pattern = re.compile(r'^[ \t]*device[ \t]+msubcircuit[ \t]+nfet_03v3_dss[ \t]'
                         r'(?:[^\n]*\\\n)*[^\n]*\n', re.M)
    if len(pattern.findall(text)) != 1:
        raise RuntimeError('expected one nfet_03v3_dss record in the tech file')
    text = pattern.sub(lambda m: ''.join(' ' + r + '\n' for r in records), text)
    path.write_text(text)


def run(name, records):
    directory = work / name
    directory.mkdir()
    techfile = directory / 'gf180mcuD.tech'
    make_tech(records, techfile)
    (directory / 'dss_test.mag').write_text((TESTDIR / 'layout.mag').read_text())
    (directory / 'run.tcl').write_text(
        'crashbackups stop\ndrc off\n'
        'tech load %s\nload dss_test\nextract all\n'
        'ext2spice lvs\next2spice -o dss_test.spice\n'
        'puts DSS_DONE\nquit -noprompt\n' % techfile)
    command = shlex.split(magic) + ['-dnull', '-noconsole', '-rcfile', '/dev/null', 'run.tcl']
    if os.environ.get('VALGRIND'):
        command = ['valgrind', '--trace-children=yes',
                   '--log-file=' + str(work / ('valgrind.' + name + '.%p.log'))] + command
    with (directory / 'magic.log').open('w') as stream:
        p = subprocess.run(command, cwd=directory, stdin=subprocess.DEVNULL,
                           stdout=stream, stderr=subprocess.STDOUT, timeout=120)
    if p.returncode or 'DSS_DONE' not in (directory / 'magic.log').read_text(errors='replace'):
        raise RuntimeError('incomplete extraction: ' + name)
    return directory / 'dss_test.spice'


def check(path):
    problems, devices = [], {}
    text = path.read_text()
    if '@' in text:
        problems.append('device record suffix in the netlist')
    for row in read_lines(path):
        if not row[0].lower().startswith('x'):
            continue
        params = dict(p.split('=', 1) for p in row if '=' in p)
        pins = [p for p in row[1:] if '=' not in p]
        if pins[-1] != 'nfet_03v3_dss':
            problems.append('unexpected device: ' + ' '.join(row))
            continue
        # Pin order is (d g s b), so d_sab belongs to pins[0], s_sab to pins[2]
        devices[pins[1]] = (pins[0], pins[2], parse_value(params['l']),
                            parse_value(params['d_sab']), parse_value(params['s_sab']))
    if sorted(devices) != ['G1', 'G2']:
        return problems + ['devices found for gates %s' % sorted(devices)]

    d, s, l, dsab, ssab = devices['G2']
    unit = l / GATE_LEN
    if sorted([d, s]) != ['D2', 'S2']:
        problems.append('two-sided device terminals %s %s' % (d, s))
    for v in (dsab, ssab):
        if abs(v - SAB_LEN * unit) > 1e-3 * SAB_LEN * unit:
            problems.append('two-sided device SAB length %g, expected %g'
                            % (v, SAB_LEN * unit))

    d, s, l, dsab, ssab = devices['G1']
    if abs(l - GATE_LEN * unit) > 1e-3 * l:
        problems.append('one-sided device length %g, expected %g' % (l, GATE_LEN * unit))
    if sorted([d, s]) != ['D1', 'S1']:
        problems.append('one-sided device terminals %s %s' % (d, s))
    else:
        sab = {d: dsab, s: ssab}
        if abs(sab['S1'] - SAB_LEN * unit) > 1e-3 * SAB_LEN * unit:
            problems.append('one-sided device SAB on the ndiffres side %g, expected %g'
                            % (sab['S1'], SAB_LEN * unit))
        if sab['D1'] != 0:
            problems.append('one-sided device SAB on the ndiff side %g, expected 0'
                            % sab['D1'])
    return problems


try:
    failures = []
    for name, records in VARIANTS.items():
        problems = check(run(name, records))
        failures += [name + ': ' + p for p in problems]
        print('  %-20s %s' % (name, 'ok' if not problems else 'FAILED'))
    if failures:
        raise RuntimeError('\n'.join(failures))
except Exception as error:
    print('FAIL:', error)
    sys.exit(1)
