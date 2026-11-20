#!/usr/bin/env python3
"""Port aliases must not provide a parallel ideal path around extracted R."""
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


def resistance(path, left, right):
    parents, elements, present, ports = {}, [], set(), set()
    def find(n):
        parents.setdefault(n, n)
        if parents[n] != n:
            parents[n] = find(parents[n])
        return parents[n]
    def join(a, b):
        parents[find(a)] = find(b)
    for row in read_lines(path):
        row = [s.lower() for s in row]
        if row[0] == '.subckt':
            ports.update(row[2:])
        elif row[0][0] in 'rcv':
            present.update(row[1:3])
            value = parse_value(row[3])
            assert math.isfinite(value) and value >= 0
            if row[0][0] == 'v':
                assert value == 0, 'unexpected nonzero source'
            if row[0][0] in 'rv':
                if value == 0:
                    join(*row[1:3])
                else:
                    elements.append((row[0], row[1:3], value))
        elif not row[0].startswith('.'):
            raise RuntimeError('unexpected device ' + row[0])
    # short none may legally remove an ideal-wire port alias.  Never use
    # an equiv to repair a retained but electrically disconnected pin.
    for line in (path.parent / 'wire.ext').read_text().splitlines():
        row = shlex.split(line.lower())
        if row and row[0] == 'equiv':
            a, b = row[1:3]
            if (a not in ports and a not in present) or (b not in ports and b not in present):
                join(a, b)
    left, right = find(left.lower()), find(right.lower())
    reduced = [(name, [find(n) for n in nodes], value) for name, nodes, value in elements]
    return effective_resistance(reduced, left, right)


try:
    content = Path(tech).read_text()
    r1 = float(re.search(r'^\s*resist\s+\(allm1\)/metal1\s+(\S+)', content, re.M)[1]) / 1000
    r2 = float(re.search(r'^\s*resist\s+\(allm2\)/metal2\s+(\S+)', content, re.M)[1]) / 1000
    failures = []
    for mode in ('off', 'strict', 'default', 'missing'):
        for policy in ('none', 'resistor', 'voltage'):
            directory = work / (mode + '_' + policy)
            directory.mkdir()
            command = shlex.split(magic) + ['-dnull', '-noconsole', '-rcfile', rc, str(TESTDIR / 'layout.tcl')]
            if os.environ.get('VALGRIND'):
                command = ['valgrind', '--trace-children=yes',
                           '--log-file=' + str(work / ('valgrind.' + directory.name + '.%p.log'))] + command
            with (directory / 'magic.log').open('w') as stream:
                p = subprocess.run(command, cwd=directory, stdout=stream, stderr=subprocess.STDOUT,
                                   env=dict(os.environ, MODE=mode, SHORT_POLICY=policy), timeout=60)
            log = (directory / 'magic.log').read_text()
            if p.returncode or 'PORT_POLICIES_DONE' not in log or 'Error in extracting' in log:
                raise RuntimeError('incomplete extraction: ' + str(directory))
            ra = r1 * 1999.5 / .5 if mode in ('strict', 'default') else 0
            rb = r2 * 99 / 2.5 if mode == 'strict' else 0
            for left, right, expected in [('A0', 'A1', ra), ('A0', 'AM', ra / 2),
                                          ('AM', 'A1', ra / 2), ('B0', 'B1', rb)]:
                actual = resistance(directory / 'wire.spice', left, right)
                # Native resistance records have milliohm resolution.
                if actual is None or not math.isclose(actual, expected, rel_tol=1e-4, abs_tol=1e-3):
                    failures.append('%s %s-%s: %s ohm, expected %g' % (directory.name, left, right, actual, expected))
            if resistance(directory / 'wire.spice', 'A0', 'B0') is not None:
                failures.append(directory.name + ': separate conductors shorted together')
            print('  %s: checked three-port wire, second wire, and isolation' % directory.name)
    if failures:
        raise RuntimeError('\n'.join(failures))
except Exception as error:
    print('FAIL:', error)
    sys.exit(1)
