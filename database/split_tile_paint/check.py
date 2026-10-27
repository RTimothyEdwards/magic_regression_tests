#!/usr/bin/env python3
#
# check.py --- Check the result of painting a box over split tiles.
#
# Usage:  check.py <case>
#
# Reads <case>_before.mag, <case>_after.mag, <case>_undo.mag and
# <case>_box.txt (layer name and box).  Checks, for every layer, that the
# area covered after the paint is exactly the area covered before, plus the
# box on the painted layer;  and that the area after "undo" is exactly the
# area before.  Also checks that no coordinate is huge (a tile running off
# to infinity).
#
# Areas are compared exactly:  each unit square is divided along both of
# its diagonals into four quarters, and a quarter is covered by a shape if
# its centroid is inside the shape.  This is exact for rectangles and 45
# degree triangles with integer coordinates.
#
# Prints one line per check and exits with status 1 if any check fails.

import sys

HUGE = 1000000

def read_mag(fname):
    """Return {layer: [(kind, x1, y1, x2, y2, corner)]}"""
    shapes = {}
    layer = None
    for line in open(fname):
        f = line.split()
        if not f:
            continue
        if f[0] == '<<':
            layer = f[1]
            continue
        if layer in (None, 'checkpaint', 'end', 'labels'):
            continue
        if f[0] == 'rect':
            shapes.setdefault(layer, []).append(('rect', *map(int, f[1:5]), None))
        elif f[0] == 'tri':
            shapes.setdefault(layer, []).append(('tri', *map(int, f[1:5]), f[5]))
    return shapes

def inside(shape, px, py):
    kind, x1, y1, x2, y2, corner = shape
    if not (x1 <= px <= x2 and y1 <= py <= y2):
        return False
    if kind == 'rect':
        return True
    w = x2 - x1
    h = y2 - y1
    u = (px - x1) / w		# 0 at left, 1 at right
    v = (py - y1) / h		# 0 at bottom, 1 at top
    if corner == 'sw':
        return u + v <= 1
    if corner == 'ne':
        return u + v >= 1
    if corner == 'se':
        return (1 - u) + v <= 1
    if corner == 'nw':
        return u + (1 - v) <= 1
    raise ValueError(corner)

# Centroids of the four quarters of a unit square (bottom, right, top, left)
QUARTERS = [(0.5, 1.0 / 6), (5.0 / 6, 0.5), (0.5, 5.0 / 6), (1.0 / 6, 0.5)]

def cover(shapes):
    """Set of covered quarters (x, y, q)"""
    out = set()
    for s in shapes:
        _, x1, y1, x2, y2, _ = s
        for x in range(x1, x2):
            for y in range(y1, y2):
                for q, (dx, dy) in enumerate(QUARTERS):
                    if inside(s, x + dx, y + dy):
                        out.add((x, y, q))
    return out

def huge(shapes):
    return any(abs(v) > HUGE for s in shapes for v in s[1:5])

def main():
    case = sys.argv[1]
    before = read_mag(case + '_before.mag')
    after = read_mag(case + '_after.mag')
    try:
        undo = read_mag(case + '_undo.mag')
    except FileNotFoundError:
        # magic did not get as far as saving after "undo";  check the
        # result of the paint anyway
        print('%s:  no result after undo (magic failed)' % case)
        undo = None
    f = open(case + '_box.txt').read().split()
    blayer, box = f[0], tuple(map(int, f[1:5]))

    status = 0 if undo is not None else 1
    results = [('after paint', after)]
    if undo is not None:
        results.append(('after undo', undo))
    layers = sorted(set(before) | set(after) | set(undo or {}) | {blayer})
    for layer in layers:
        b = cover(before.get(layer, []))
        expect = b | cover([('rect', *box, None)]) if layer == blayer else b
        for name, result in results:
            want = expect if name == 'after paint' else b
            if huge(result.get(layer, [])):
                print('%s %s %s:  tile with huge coordinates' % (case, name, layer))
                status = 1
                continue
            got = cover(result.get(layer, []))
            if got == want:
                print('%s %s %s:  ok' % (case, name, layer))
            else:
                print('%s %s %s:  %g missing, %g extra (square units)' %
		      (case, name, layer, len(want - got) / 4.0, len(got - want) / 4.0))
                status = 1
    sys.exit(status)

main()
