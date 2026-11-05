#!/usr/bin/env python3
#
# check.py --- Check that the resistors in a netlist connect ports "a" and "b"
# and that their lengths add up to the expected length.
#
# Usage:  check.py <file.spice> <expected length, um> <expected count>

import re
import sys

expect = float(sys.argv[2])
count = int(sys.argv[3])
net = {}
def find(n):
    net.setdefault(n, n)
    while net[n] != n:
        n = net[n]
    return n

total = 0.0
found = 0
with open(sys.argv[1]) as f:
    for line in f:
        tok = line.split()
        if not tok or tok[0][0] not in 'XR':
            continue
        m = re.search(r'\bl=([0-9.eE+-]+)', line)
        if m is None:
            continue
        found += 1
        total += float(m.group(1))
        net[find(tok[1])] = find(tok[2])

if find('a') != find('b'):
    print('FAIL:  ports a and b are not connected (%d devices)' % found)
elif found != count or abs(total - expect) > 0.0005 * expect:
    print('FAIL:  %d devices, total length %.5g (expected %d, %.5g)'
            % (found, total, count, expect))
else:
    print('ok:  %d devices, total length %.5g' % (found, total))
