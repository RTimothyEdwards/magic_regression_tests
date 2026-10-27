#!/usr/bin/env python3
#
# gdsflat.py --- Compare the flattened geometry of GDS layer 68/20 in the
# top cells of two GDS files.
#
# Usage:  gdsflat.py <reference.gds> <test.gds>
# Prints:  "AREA ref=<area> test=<area> xor=<area>" (in square nm)
#
# Boundaries must be rectangles.  SREFs and AREFs with reflection,
# magnification, and 90-degree rotations are supported.  The structure
# names in the two files need not match (only the geometry is compared).

import math
import struct
import sys

def gds_real(b):
    sign = -1 if b[0] & 0x80 else 1
    exp = (b[0] & 0x7f) - 64
    mant = int.from_bytes(b[1:8], 'big')
    return sign * mant * 16.0 ** exp / 2 ** 56

def parse(fname):
    data = open(fname, 'rb').read()
    cells = {}
    dbunit = None
    i = 0
    cur = None
    while i < len(data):
        ln, rt, _ = struct.unpack('>HBB', data[i:i + 4])
        if ln < 4:
            break
        body = data[i + 4:i + ln]
        if rt == 0x03:
            dbunit = gds_real(body[8:16])
        elif rt == 0x06:
            cur = body.rstrip(b'\0').decode()
            cells[cur] = {'boxes': [], 'refs': []}
        elif rt in (0x08, 0x0a, 0x0b):
            elem, lay, dt, sname = rt, None, None, None
            refl, mag, angle, colrow = False, 1.0, 0.0, (1, 1)
        elif rt == 0x0d:
            lay = struct.unpack('>h', body)[0]
        elif rt == 0x0e:
            dt = struct.unpack('>h', body)[0]
        elif rt == 0x12:
            sname = body.rstrip(b'\0').decode()
        elif rt == 0x13:
            colrow = struct.unpack('>hh', body)
        elif rt == 0x1a:
            refl = (struct.unpack('>H', body)[0] & 0x8000) != 0
        elif rt == 0x1b:
            mag = gds_real(body)
        elif rt == 0x1c:
            angle = gds_real(body)
        elif rt == 0x10:
            xy = struct.unpack('>%di' % (len(body) // 4), body)
        elif rt == 0x11:
            if elem == 0x08 and lay == 68 and dt == 20:
                xs, ys = xy[0::2], xy[1::2]
                cells[cur]['boxes'].append((min(xs), min(ys), max(xs), max(ys)))
            elif elem == 0x0a:
                cells[cur]['refs'].append((sname, refl, mag, angle, xy[0], xy[1]))
            elif elem == 0x0b:
                cols, rows = colrow
                dx = ((xy[2] - xy[0]) / cols, (xy[3] - xy[1]) / cols)
                dy = ((xy[4] - xy[0]) / rows, (xy[5] - xy[1]) / rows)
                for c in range(cols):
                    for r in range(rows):
                        cells[cur]['refs'].append((sname, refl, mag, angle,
                                xy[0] + c * dx[0] + r * dy[0],
                                xy[1] + c * dx[1] + r * dy[1]))
        i += ln
    # Convert to nm
    scale = dbunit / 1e-9
    return cells, scale

def flatten(cells, name, tf, out):
    for (x1, y1, x2, y2) in cells[name]['boxes']:
        ax, ay = tf(x1, y1)
        bx, by = tf(x2, y2)
        out.append((min(ax, bx), min(ay, by), max(ax, bx), max(ay, by)))
    for (sname, refl, mag, ang, ox, oy) in cells[name]['refs']:
        a = round(ang) % 360
        c = round(math.cos(math.radians(a)))
        s = round(math.sin(math.radians(a)))
        def t(x, y, refl=refl, mag=mag, c=c, s=s, ox=ox, oy=oy, tf=tf):
            if refl:
                y = -y
            x *= mag
            y *= mag
            return tf(c * x - s * y + ox, s * x + c * y + oy)
        flatten(cells, sname, t, out)
    return out

def flat(fname):
    cells, scale = parse(fname)
    used = {r[0] for c in cells.values() for r in c['refs']}
    tops = [c for c in cells if c not in used]
    rects = []
    for top in tops:
        flatten(cells, top, lambda x, y: (x * scale, y * scale), rects)
    # Round to 0.01nm to remove floating-point noise
    return [tuple(round(v, 2) for v in r) for r in rects]

def cover(rects, xs, ys):
    """Set of grid cells (in the coordinates xs, ys) covered by rects"""
    xi = {x: i for i, x in enumerate(xs)}
    yi = {y: i for i, y in enumerate(ys)}
    cells = set()
    for (x1, y1, x2, y2) in rects:
        for i in range(xi[x1], xi[x2]):
            for j in range(yi[y1], yi[y2]):
                cells.add((i, j))
    return cells

def area(cells, xs, ys):
    return sum((xs[i + 1] - xs[i]) * (ys[j + 1] - ys[j]) for (i, j) in cells)

def main():
    ra = flat(sys.argv[1])
    rb = flat(sys.argv[2])
    xs = sorted({v for r in ra + rb for v in (r[0], r[2])})
    ys = sorted({v for r in ra + rb for v in (r[1], r[3])})
    ca = cover(ra, xs, ys)
    cb = cover(rb, xs, ys)
    print('AREA ref=%g test=%g xor=%g' % (area(ca, xs, ys), area(cb, xs, ys),
                                          area(ca ^ cb, xs, ys)))

main()
