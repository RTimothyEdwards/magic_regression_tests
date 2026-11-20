#!/usr/bin/env python3
"""Split-tile labels and RC start points must select the actual conductor."""
import math
import os
from pathlib import Path
import shlex
import subprocess
import sys

TESTDIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TESTDIR.parent.parent / 'common'))
from gdslib import i2, i4, library, rec, structure, text
from spicenet import effective_resistance, parse

magic, pdk, work = sys.argv[1:]
work = Path(work)
rc = str(Path(pdk) / 'sky130A/libs.tech/magic/sky130A.magicrc')


def transform(point, rotation, mirror):
    x, y = point
    if mirror:
        x = -x
    for _ in range(rotation):
        x, y = -y, x
    return (round(x * 1000), round(y * 1000))


def run(name, shape, pins, rotation, mirror, outside=False):
    directory = work / name
    directory.mkdir()
    vertices = [transform(p, rotation, mirror) for p in shape]
    points = [v for p in vertices + vertices[:1] for v in p]
    body = (rec(0x08, 0) + rec(0x0d, 2, i2(68)) + rec(0x0e, 2, i2(20)) +
            rec(0x10, 3, i4(*points)) + rec(0x11, 0))
    for label, point in pins:
        body += text(*transform(point, rotation, mirror), label, layer=68, datatype=5)
    (directory / 'wire.gds').write_bytes(library([structure('wire', body)]))
    script = '''crashbackups stop
drc off
gds read wire.gds
load wire
select top cell
port makeall
extract all
ext2spice lvs
ext2spice subcircuit top on
ext2spice cthresh 0
ext2spice extresist off
ext2spice -o lumped.spice
'''
    if not outside:
        script += '''extresist threshold 0
extresist mindelay 0
extresist minres 0
extresist prune 0
extresist
ext2spice extresist on
ext2spice -o rc.spice
'''
    script += 'puts SPLIT_PORTS_DONE\nquit -noprompt\n'
    (directory / 'run.tcl').write_text(script)
    command = shlex.split(magic) + ['-dnull', '-noconsole', '-rcfile', rc, 'run.tcl']
    if os.environ.get('VALGRIND'):
        command = ['valgrind', '--trace-children=yes',
                   '--log-file=' + str(work / ('valgrind.' + name + '.%p.log'))] + command
    with (directory / 'magic.log').open('w') as stream:
        p = subprocess.run(command, cwd=directory, stdout=stream, stderr=subprocess.STDOUT, timeout=60)
    log = (directory / 'magic.log').read_text()
    if p.returncode or 'SPLIT_PORTS_DONE' not in log or 'Error in extracting node' in log or "Couldn't find" in log:
        failures.append(name + ': extraction did not complete successfully')
        return
    records = [shlex.split(line) for line in (directory / 'wire.ext').read_text().splitlines()]
    if outside:
        node = next((row for row in records if row[:2] == ['node', 'OUTSIDE']), None)
        if node is None or any(float(node[i]) != 0 for i in range(7, len(node), 2)):
            failures.append(name + ': label in empty half attached to conductor')
        if any(row and row[0] == 'equiv' and 'OUTSIDE' in row[1:3] for row in records):
            failures.append(name + ': empty-half label aliases conductor')
        print('  %s: empty-half label remains separate' % name)
        return
    subs, elements = parse(directory / 'rc.spice')
    sub = subs[-1][0]
    resistance = effective_resistance(elements, (sub, 'A'), (sub, 'B'))
    if resistance is None or not math.isfinite(resistance) or resistance <= 0:
        failures.append(name + ': missing positive finite port resistance: ' + str(resistance))
    _, original = parse(directory / 'lumped.spice')
    def capacitance(items):
        return sum(v for n, _, v in items if n[0].lower() == 'c' and v is not None)
    c0, c1 = capacitance(original), capacitance(elements)
    if c0 <= 0 or not math.isclose(c0, c1, rel_tol=1e-4, abs_tol=1e-21):
        failures.append('%s: capacitance changed %g -> %g' % (name, c0, c1))
    print('  %s: R(A,B)=%s ohm; C=%g fF' % (name, resistance, c1 * 1e15))


try:
    failures = []
    triangle = [(0, 0), (100, 0), (0, 100)]
    cases = [('interior', triangle, [('A', (10, 10)), ('B', (75, 10))], False),
             ('edge', triangle, [('A', (20, 80)), ('B', (80, 20))], False),
             ('diagonal_wire', [(0, 0), (100, 100), (100, 102), (0, 2)],
              [('A', (1, 2)), ('B', (99, 100))], False),
             ('outside', triangle, [('A', (10, 10)), ('OUTSIDE', (75, 75))], True)]
    for name, shape, pins, outside in cases:
        for rotation in range(4):
            for mirror in (False, True):
                run('%s_r%d_m%d' % (name, rotation, mirror), shape, pins, rotation, mirror, outside)
    if failures:
        raise RuntimeError('\n'.join(failures))
except Exception as error:
    print('FAIL:', error)
    sys.exit(1)
