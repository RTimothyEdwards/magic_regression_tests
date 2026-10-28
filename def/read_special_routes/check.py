#!/usr/bin/env python3
#
# check.py --- Check the wires read from test.def (written by magic as
# out.gds).
#
# Usage:  check.py out.gds
#
# Each special net wire must cover exactly the band given by its
# centerline and width, along the whole length of the wire (0 to 50um), and
# no more than that, other than an extension of at most half the width at
# each end.  For the regular net VDD (whose width comes from the tech
# file), only the presence of the wire along its centerline is checked.

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                '..', '..', 'common'))
import gdslib

M4 = (46, 0)
M5 = (81, 0)
LENGTH = 50000

# (name, layer, centerline y, width) in nm;  width None:  check presence only
WIRES = [
    ('VDD (net) Metal4', M4, 5500, None),
    ('VDD (net) Metal5', M5, 7500, None),
    ('VSS ROUTED Metal4', M4, 10500, 500),
    ('VSS ROUTED Metal5', M5, 12500, 500),
    ('VDD2 FIXED Metal4', M4, 20500, 300),
    ('VDD2 FIXED Metal5', M5, 22500, 300),
    ('VSS2 COVER Metal4', M4, 30500, 400),
    ('VSS2 ROUTED Metal5', M5, 32500, 400),
    ('VSS2 NEW Metal4', M4, 34500, 400),
    ('VSS3 ROUTED Metal5', M5, 42500, 200),
    ('VSS3 SHIELD Metal4', M4, 40500, 200),
]

def covered(rects, box):
    """Area of the union of rects inside box"""
    x1, y1, x2, y2 = box
    clipped = []
    for (a, b, c, d) in rects:
        a, b, c, d = max(a, x1), max(b, y1), min(c, x2), min(d, y2)
        if a < c and b < d:
            clipped.append((a, b, c, d))
    xs = sorted({v for r in clipped for v in (r[0], r[2])})
    ys = sorted({v for r in clipped for v in (r[1], r[3])})
    return gdslib._area(gdslib._cover(clipped, xs, ys), xs, ys)

status = 0
layers = {M4: gdslib.flat(sys.argv[1], *M4), M5: gdslib.flat(sys.argv[1], *M5)}
for name, layer, y, w in WIRES:
    rects = layers[layer]
    if w is None:
        # The centerline (as a thin band) must be covered
        ok = covered(rects, (0, y - 1, LENGTH, y + 1)) == LENGTH * 2
        msg = 'ok' if ok else 'missing'
    else:
        full = LENGTH * w
        inside = covered(rects, (0, y - w / 2, LENGTH, y + w / 2))
        # Everything on the layer near the wire:  must not be wider than
        # the wire, nor extend more than w/2 beyond each end
        near = covered(rects, (-5000, y - w / 2 - 100, LENGTH + 5000,
                               y + w / 2 + 100))
        ok = inside == full and near <= full + w * w
        if inside == 0:
            msg = 'missing'
        elif inside < full:
            msg = 'incomplete (%g of %g square nm)' % (inside, full)
        elif near > full + w * w:
            msg = 'too large (%g square nm, expected %g)' % (near, full)
        else:
            msg = 'ok'
    print('%-20s %s' % (name, msg))
    if not ok:
        status = 1
sys.exit(status)
