#!/usr/bin/env python3
#
# check.py --- Compare the capacitance of a netlist with and without the
# extresist network.  Nets are identified by the resistors connecting them,
# so this does not depend on the names of the network's nodes.  Capacitance
# to substrate (a net named "w_...") and capacitance between different nets
# must each have the same total.
#
# Usage:  check.py <spicenet.py directory> <lumped.spice> <network.spice>

import re
import sys

sys.path.insert(0, sys.argv[1])
from spicenet import parse

def totals(path):
    _, elements = parse(path)
    net = {}
    def find(n):
        net.setdefault(n, n)
        while net[n] != n:
            n = net[n]
        return n
    for name, nodes, _ in elements:
        if name[0].lower() == 'r':
            net[find(nodes[0][1])] = find(nodes[1][1])
    subs = couple = 0.0
    for name, nodes, value in elements:
        if name[0].lower() != 'c' or not value:
            continue
        n1, n2 = nodes[0][1], nodes[1][1]
        if re.match('w_', n1) or re.match('w_', n2):
            subs += value
        elif find(n1) != find(n2):
            couple += value
    return subs * 1e15, couple * 1e15

ls, lc = totals(sys.argv[2])
ns, nc = totals(sys.argv[3])
bad = (lc <= 0) or (abs(ns - ls) > 0.005 * ls) or (abs(nc - lc) > 0.005 * lc)
print('%s:  substrate %.4g (lumped %.4g) fF, coupling %.4g (lumped %.4g) fF'
        % ('FAIL' if bad else 'ok', ns, ls, nc, lc))
