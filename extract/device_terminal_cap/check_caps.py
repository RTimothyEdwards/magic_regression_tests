#!/usr/bin/env python3
#
# check_caps.py --- Compare the capacitors in a netlist against the expected
# values, by the subcircuit and the pair of nets they connect.
#
# Usage:  check_caps.py <file> <cell> "<subckt>:<net1>:<net2>=<fF>" ...
#
# An empty subcircuit name is the cell itself, whether or not the netlist
# puts it in a subcircuit.  Any capacitor that was not expected, and any
# expected capacitor that is missing, is an error.

import sys

sys.path.insert(0, sys.argv[0].rsplit('/', 1)[0] + '/../../common')
from spicenet import parse_value

found = {}
subckt = ''
for line in open(sys.argv[1]):
    tokens = line.split()
    if not tokens:
        continue
    if tokens[0].lower() == '.subckt':
        subckt = '' if tokens[1] == sys.argv[2] else tokens[1]
    elif tokens[0].lower() == '.ends':
        subckt = ''
    elif tokens[0][0] in 'Cc':
        key = (subckt, *sorted(tokens[1:3]))
        found[key] = found.get(key, 0) + parse_value(tokens[3]) * 1e15

errors = 0
for item in sys.argv[3:]:
    name, value = item.split('=')
    sub, net1, net2 = name.split(':')
    key = (sub, *sorted((net1, net2)))
    have = found.pop(key, None)
    if have is None or abs(have - float(value)) > 1e-4:
        print('    %s: expected %s fF, got %s' % (name, value, have))
        errors += 1
for key, have in found.items():
    print('    %s: unexpected capacitor of %g fF' % (':'.join(key), have))
    errors += 1
sys.exit(1 if errors else 0)
