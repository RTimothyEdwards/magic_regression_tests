#!/usr/bin/env python3
#
# check.py --- Compare the flattened arrays in test.gds and flat.gds, case
# by case (each case occupies a 20um x 20um region;  see mkgds.py).
#
# Usage:  check.py <test.gds> <flat.gds>
# Prints one line per case and exits with status 1 if any case differs.

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                '..', '..', 'common'))
import gdslib

CASES = [('finegrid', 0, 0), ('plain', 20000, 0), ('r90', 40000, 0),
         ('r270', 60000, 0), ('m90', 80000, 0), ('col1', 0, 20000),
         ('row1', 20000, 20000), ('col1r90', 40000, 20000),
         ('row1r90', 60000, 20000)]

def clip(rects, x, y):
    """Rectangles clipped to the 20um square centered on (x, y)"""
    out = []
    for (a, b, c, d) in rects:
        a, b = max(a, x - 10000), max(b, y - 10000)
        c, d = min(c, x + 10000), min(d, y + 10000)
        if a < c and b < d:
            out.append((a, b, c, d))
    return out

ref = gdslib.flat(sys.argv[1], 68, 20)
out = gdslib.flat(sys.argv[2], 68, 20)
status = 0
for name, x, y in CASES:
    ra = clip(ref, x, y)
    rb = clip(out, x, y)
    xs = sorted({v for r in ra + rb for v in (r[0], r[2])})
    ys = sorted({v for r in ra + rb for v in (r[1], r[3])})
    ca = gdslib._cover(ra, xs, ys)
    cb = gdslib._cover(rb, xs, ys)
    xor = gdslib._area(ca ^ cb, xs, ys)
    print('%-9s %s' % (name, 'ok' if xor == 0 else
          'differs:  %g square nm (expected area %g)' % (xor, gdslib._area(ca, xs, ys))))
    if xor != 0:
        status = 1
sys.exit(status)
