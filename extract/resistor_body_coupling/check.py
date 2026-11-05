#!/usr/bin/env python3
#
# check.py --- Check coupling capacitors in a netlist written from a layout of
# two resistors.  The total between the two nets must match the sum of the
# "cap" records in the .ext file, and each capacitor must connect to nodes that
# something else in the netlist also connects to.
#
# Usage:  check.py <spicenet.py directory> <file.ext> <file.spice>

import shlex
import sys

sys.path.insert(0, sys.argv[1])
from spicenet import parse

extcap = 0.0
with open(sys.argv[2]) as f:
    for line in f:
        tok = shlex.split(line)
        if tok and tok[0] == 'cap':
            extcap += float(tok[3])

subckts, elements = parse(sys.argv[3])
pins = {p for _, plist in subckts for p in plist}
others = set(pins)
for name, nodes, _ in elements:
    if name[0].lower() != 'c':
        others.update(n for _, n in nodes)

net = {}
def find(n):
    net.setdefault(n, n)
    while net[n] != n:
        n = net[n]
    return n
for name, nodes, _ in elements:
    if name[0].lower() in 'rx':
        terms = [n for _, n in nodes][:2]
        net[find(terms[0])] = find(terms[1])

total = 0.0
floating = []
for name, nodes, value in elements:
    if name[0].lower() != 'c' or not value:
        continue
    n1, n2 = nodes[0][1], nodes[1][1]
    if n1.startswith('w_') or n2.startswith('w_') or 'SUB' in (n1 + n2).upper():
        continue
    for n in (n1, n2):
        if n not in others:
            floating.append(n)
    total += value * 1e15

total_ext = extcap / 1000
bad = floating or (total_ext <= 0) or (abs(total - total_ext) > 0.01 * total_ext)
print('%s:  coupling %.4g fF (.ext %.4g fF)%s' % ('FAIL' if bad else 'ok', total,
        total_ext, '  floating: ' + ' '.join(sorted(set(floating))) if floating else ''))
