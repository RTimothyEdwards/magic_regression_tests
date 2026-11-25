#!/usr/bin/env python3
"""Two ports on the same point of an extracted wire must stay connected."""
import math
import os
from pathlib import Path
import shlex
import subprocess
import sys

TESTDIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TESTDIR.parent.parent / 'common'))
from spicenet import parse_value, read_lines

magic, pdk, work = sys.argv[1:]
work = Path(work)
rc = str(Path(pdk) / 'sky130A/libs.tech/magic/sky130A.magicrc')


def run(mode, policy, order):
    directory = work / ('%s_%s_%s' % (mode, policy, order))
    directory.mkdir()
    command = shlex.split(magic) + ['-dnull', '-noconsole', '-rcfile', rc,
                                    str(TESTDIR / 'layout.tcl')]
    if os.environ.get('VALGRIND'):
        command = ['valgrind', '--trace-children=yes', '--log-file=' +
                   str(work / ('valgrind.' + directory.name + '.%p.log'))] + command
    with (directory / 'magic.log').open('w') as stream:
        p = subprocess.run(command, cwd=directory, stdin=subprocess.DEVNULL,
                           stdout=stream, stderr=subprocess.STDOUT, timeout=60,
                           env=dict(os.environ, MODE=mode, SHORT_POLICY=policy,
                                    ORDER=order))
    log = (directory / 'magic.log').read_text(errors='replace')
    if p.returncode or 'COINCIDENT_PORTS_DONE' not in log:
        raise RuntimeError('incomplete extraction: ' + directory.name)
    return directory


def check(directory, policy):
    """Return (problems, total capacitance) for one netlist."""
    problems, ports, used, cap = [], [], set(), 0.0
    ideal = {'resistor': 'r', 'voltage': 'v'}.get(policy)
    shorted = False
    for row in read_lines(directory / 'wire.spice'):
        row = [s.lower() for s in row]
        if row[0] == '.subckt':
            ports = row[2:]
        elif row[0][0] in 'rcv':
            value = parse_value(row[3])
            if not math.isfinite(value) or value < 0:
                problems.append('bad value: ' + ' '.join(row))
            used.update(row[1:3])
            if row[0][0] == 'c':
                cap += value
            elif value == 0 and set(row[1:3]) == {'a', 'b'}:
                if row[0][0] == ideal:
                    shorted = True
                else:
                    problems.append('wrong short element: ' + ' '.join(row))
        elif not row[0].startswith('.'):
            problems.append('unexpected device: ' + row[0])
    for port in ports:
        if port not in used:
            problems.append('port %s is not connected to anything' % port)
    if policy == 'none':
        if sorted(ports) not in (['a'], ['b']):
            problems.append('ports %s: expected A and B merged' % ports)
    else:
        if sorted(ports) != ['a', 'b']:
            problems.append('ports %s: expected both A and B' % ports)
        if not shorted:
            problems.append('no zero-valued %s between A and B' % policy)
    return problems, cap


try:
    failures, reference = [], None
    for order in ('ab', 'ba'):
        for mode in ('off', 'strict', 'default'):
            for policy in ('none', 'resistor', 'voltage'):
                directory = run(mode, policy, order)
                problems, cap = check(directory, policy)
                # Capacitance does not depend on how the ports are joined.
                if reference is None:
                    reference = cap
                if cap <= 0 or not math.isclose(cap, reference, rel_tol=1e-3):
                    problems.append('total C %g, expected %g' % (cap, reference))
                failures += [directory.name + ': ' + s for s in problems]
                print('  %-22s %s' % (directory.name,
                                      'ok' if not problems else 'FAILED'))
    if failures:
        raise RuntimeError('\n'.join(failures))
except Exception as error:
    print('FAIL:', error)
    sys.exit(1)
