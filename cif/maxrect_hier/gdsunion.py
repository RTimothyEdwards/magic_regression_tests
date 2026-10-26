#!/usr/bin/env python3
#
# gdsunion.py --- Flatten one GDS layer/datatype of the top cell of a GDS
# file and report whether its union is a single solid rectangle.
#
# Usage:  gdsunion.py <file.gds> <layer> <datatype>
# Prints:  "UNION bbox=(x1,y1,x2,y2) area=<union area> solid=<0|1>"
# Only boundaries that are rectangles and SREFs with 90-degree rotations
# are supported (enough for the test layouts).

import math
import struct
import sys

def gds_real(b):
    sign = -1 if b[0] & 0x80 else 1
    exp = (b[0] & 0x7f) - 64
    mant = int.from_bytes(b[1:8], 'big')
    return sign * mant * 16.0 ** exp / 2 ** 56

def parse(fname, layer, datatype):
    data = open(fname, 'rb').read()
    cells = {}
    i = 0
    cur = elem = None
    while i < len(data):
        ln, rt, _ = struct.unpack('>HBB', data[i:i + 4])
        if ln < 4:
            break
        body = data[i + 4:i + ln]
        if rt == 0x06:
            cur = body.rstrip(b'\0').decode()
            cells[cur] = {'boxes': [], 'refs': []}
        elif rt in (0x08, 0x0a, 0x0b):
            elem, lay, dt, sname, strans, angle = rt, None, None, None, 0, 0.0
        elif rt == 0x0d:
            lay = struct.unpack('>h', body)[0]
        elif rt == 0x0e:
            dt = struct.unpack('>h', body)[0]
        elif rt == 0x12:
            sname = body.rstrip(b'\0').decode()
        elif rt == 0x1a:
            strans = struct.unpack('>H', body)[0]
        elif rt == 0x1c:
            angle = gds_real(body)
        elif rt == 0x10:
            xy = struct.unpack('>%di' % (len(body) // 4), body)
        elif rt == 0x11:
            if elem == 0x08 and lay == layer and dt == datatype:
                xs, ys = xy[0::2], xy[1::2]
                cells[cur]['boxes'].append((min(xs), min(ys), max(xs), max(ys)))
            elif elem == 0x0a:
                cells[cur]['refs'].append((sname, strans & 0x8000, angle,
                                           xy[0], xy[1]))
        i += ln
    return cells

def flatten(cells, name, tf, out):
    for (x1, y1, x2, y2) in cells[name]['boxes']:
        ax, ay = tf(x1, y1)
        bx, by = tf(x2, y2)
        out.append((min(ax, bx), min(ay, by), max(ax, bx), max(ay, by)))
    for (sname, refl, ang, ox, oy) in cells[name]['refs']:
        a = round(ang) % 360
        c = round(math.cos(math.radians(a)))
        s = round(math.sin(math.radians(a)))
        def t(x, y, refl=refl, c=c, s=s, ox=ox, oy=oy, tf=tf):
            if refl:
                y = -y
            return tf(c * x - s * y + ox, s * x + c * y + oy)
        flatten(cells, sname, t, out)
    return out

def main():
    cells = parse(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
    used = {r[0] for c in cells.values() for r in c['refs']}
    top = [c for c in cells if c not in used][0]
    rects = flatten(cells, top, lambda x, y: (x, y), [])
    if not rects:
        print('UNION empty')
        return
    xs = sorted({r[0] for r in rects} | {r[2] for r in rects})
    ys = sorted({r[1] for r in rects} | {r[3] for r in rects})
    covered = set()
    for (x1, y1, x2, y2) in rects:
        for i in range(xs.index(x1), xs.index(x2)):
            for j in range(ys.index(y1), ys.index(y2)):
                covered.add((i, j))
    area = sum((xs[i + 1] - xs[i]) * (ys[j + 1] - ys[j]) for (i, j) in covered)
    bbox = (xs[0], ys[0], xs[-1], ys[-1])
    full = (xs[-1] - xs[0]) * (ys[-1] - ys[0])
    print('UNION bbox=(%d,%d,%d,%d) area=%d solid=%d' % (bbox + (area, int(area == full))))

main()
