#!/usr/bin/env python3
#
# check.py --- Check that the label "A" in <cell>.mag is attached to metal1
# and lies entirely on metal1.
#
# Usage:  check.py <cell>

import sys

rects = []
labels = []
layer = None
for line in open(sys.argv[1] + '.mag'):
    f = line.split()
    if not f:
        continue
    if f[0] == '<<':
        layer = f[1]
    elif f[0] == 'rect' and layer == 'metal1':
        rects.append(tuple(map(int, f[1:5])))
    elif f[0] == 'rlabel':
        labels.append((f[1], tuple(map(int, f[2:6]))))

if len(labels) != 1:
    print('%s:  %d labels, expected 1' % (sys.argv[1], len(labels)))
    sys.exit(1)
ltype, (x1, y1, x2, y2) = labels[0]
if ltype != 'metal1':
    print('%s:  label is attached to "%s", expected metal1' % (sys.argv[1], ltype))
    sys.exit(1)

def on_metal(px, py):
    return any(a <= px <= c and b <= py <= d for (a, b, c, d) in rects)

# Check every point of the label area on a half-unit grid (shapes and
# labels have integer coordinates)
inside = all(on_metal(x1 + i / 2.0, y1 + j / 2.0)
             for i in range(2 * (x2 - x1) + 1) for j in range(2 * (y2 - y1) + 1))
if not inside:
    print('%s:  label area (%d %d %d %d) is not entirely on metal1' %
          (sys.argv[1], x1, y1, x2, y2))
    sys.exit(1)
print('%s:  label on metal1 at (%d %d %d %d)' % (sys.argv[1], x1, y1, x2, y2))
