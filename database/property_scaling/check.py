#!/usr/bin/env python3
#
# check.py --- Check props.txt (see prop.tcl).
#
# After "scalegrid 1 2", the paint bounding box, FIXED_BBOX, and every mask
# hint rectangle must be exactly twice their starting values.  After "move
# origin", FIXED_BBOX and the mask hints must have moved by the same amount
# as the paint.  Mask hints are compared as a set of rectangles, as their
# order is not significant.

import sys

def parse(line):
    step, rest = line.split(' ', 1)
    paint, fixed, hints = [list(map(int, part.split())) for part in rest.split('|')]
    rects = sorted(tuple(hints[i:i + 4]) for i in range(0, len(hints), 4))
    return step, paint, fixed, rects

steps = {}
for line in open(sys.argv[1]):
    if line.strip():
        step, paint, fixed, rects = parse(line)
        steps[step] = (paint, fixed, rects)

status = 0
def check(name, got, want):
    global status
    if got == want:
        print('%-26s ok' % name)
    else:
        print('%-26s %s, expected %s' % (name, got, want))
        status = 1

for step in ('start', 'scaled', 'moved'):
    if step not in steps:
        print('no result for step "%s"' % step)
        sys.exit(1)

p0, f0, h0 = steps['start']
p1, f1, h1 = steps['scaled']
p2, f2, h2 = steps['moved']

check('scalegrid:  paint', p1, [2 * v for v in p0])
check('scalegrid:  FIXED_BBOX', f1, [2 * v for v in f0])
check('scalegrid:  MASKHINTS_m2', h1, sorted(tuple(2 * v for v in r) for r in h0))

dx = p2[0] - p1[0]
dy = p2[1] - p1[1]
move = lambda r: tuple(v + (dx if i % 2 == 0 else dy) for i, v in enumerate(r))
check('move origin:  FIXED_BBOX', f2, list(move(f1)))
check('move origin:  MASKHINTS_m2', h2, sorted(move(r) for r in h1))
sys.exit(status)
