#!/usr/bin/env python3
#
# gdslib.py --- Small GDS writer and flattener for the regression tests.
#
# Writing:  build records with the functions below and pass the structures
# to library().  Units are fixed at 1nm.
#
# Reading:  compare(ref, test, layer, datatype) flattens the given layer of
# the top cell(s) of two GDS files and returns the areas (in square nm)
# covered in each and covered by only one of them.  Only rectangular
# boundaries are supported, and SREFs and AREFs with reflection,
# magnification, and rotations by multiples of 90 degrees.  Structure names
# in the two files do not need to match.

import math
import struct

# ---------------------------------------------------------------------
# Writing
# ---------------------------------------------------------------------

def real8(v):
    """Encode a GDS 8-byte real"""
    if v == 0:
        return b'\0' * 8
    sign = 0x80 if v < 0 else 0
    v = abs(v)
    exp = 64
    while v >= 1:
        v /= 16.0
        exp += 1
    while v < 1.0 / 16:
        v *= 16.0
        exp -= 1
    mant = int(round(v * 2 ** 56))
    if mant >= 2 ** 56:
        mant //= 16
        exp += 1
    return bytes([sign | exp]) + mant.to_bytes(7, 'big')

def rec(rtype, dtype, data=b''):
    if len(data) % 2:
        data += b'\0'
    return struct.pack('>HBB', len(data) + 4, rtype, dtype) + data

def i2(*v):
    return struct.pack('>%dh' % len(v), *v)

def i4(*v):
    return struct.pack('>%di' % len(v), *v)

STAMP = i2(126, 1, 1, 0, 0, 0) * 2

def boundary(x1, y1, x2, y2, layer=68, datatype=20):
    return (rec(0x08, 0) + rec(0x0d, 2, i2(layer)) + rec(0x0e, 2, i2(datatype)) +
            rec(0x10, 3, i4(x1, y1, x2, y1, x2, y2, x1, y2, x1, y1)) +
            rec(0x11, 0))

def strans(mag=1, angle=0, reflect=False):
    if mag == 1 and angle == 0 and not reflect:
        return b''
    out = rec(0x1a, 1, struct.pack('>H', 0x8000 if reflect else 0))
    if mag != 1:
        out += rec(0x1b, 5, real8(mag))
    if angle != 0:
        out += rec(0x1c, 5, real8(angle))
    return out

def sref(name, x, y, mag=1, angle=0, reflect=False):
    return (rec(0x0a, 0) + rec(0x12, 6, name.encode()) +
            strans(mag, angle, reflect) + rec(0x10, 3, i4(x, y)) + rec(0x11, 0))

def aref(name, cols, rows, points, mag=1, angle=0, reflect=False):
    """AREF with the three reference points given explicitly:
    origin, origin + cols * column step, origin + rows * row step
    (the steps are in the parent's coordinates)."""
    xy = [v for p in points for v in p]
    return (rec(0x0b, 0) + rec(0x12, 6, name.encode()) +
            strans(mag, angle, reflect) + rec(0x13, 2, i2(cols, rows)) +
            rec(0x10, 3, i4(*xy)) + rec(0x11, 0))

def structure(name, body):
    return (rec(0x05, 2, STAMP) + rec(0x06, 6, name.encode()) + body +
            rec(0x07, 0))

def library(structures, libname='TEST'):
    """Return the bytes of a GDS file (units 1nm) containing the structures"""
    return (rec(0x00, 2, i2(600)) + rec(0x01, 2, STAMP) +
            rec(0x02, 6, libname.encode()) +
            rec(0x03, 5, real8(0.001) + real8(1e-9)) +
            b''.join(structures) + rec(0x04, 0))

# ---------------------------------------------------------------------
# Reading and flattening
# ---------------------------------------------------------------------

def gds_real(b):
    sign = -1 if b[0] & 0x80 else 1
    exp = (b[0] & 0x7f) - 64
    mant = int.from_bytes(b[1:8], 'big')
    return sign * mant * 16.0 ** exp / 2 ** 56

def parse(fname, layer, datatype):
    """Return ({structure: {'boxes': [...], 'refs': [...]}}, nm per unit)"""
    data = open(fname, 'rb').read()
    cells = {}
    dbunit = 1e-9
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
            if elem == 0x08 and lay == layer and dt == datatype:
                xs, ys = xy[0::2], xy[1::2]
                cells[cur]['boxes'].append((min(xs), min(ys), max(xs), max(ys)))
            elif elem == 0x0a:
                cells[cur]['refs'].append((sname, refl, mag, angle, xy[0], xy[1]))
            elif elem == 0x0b:
                # The step in a direction with only one element is never
                # used, so a bogus value there does not matter.
                cols, rows = colrow
                dx = ((xy[2] - xy[0]) / cols, (xy[3] - xy[1]) / cols)
                dy = ((xy[4] - xy[0]) / rows, (xy[5] - xy[1]) / rows)
                for c in range(cols):
                    for r in range(rows):
                        cells[cur]['refs'].append((sname, refl, mag, angle,
                                xy[0] + c * dx[0] + r * dy[0],
                                xy[1] + c * dx[1] + r * dy[1]))
        i += ln
    return cells, dbunit / 1e-9

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

def flat(fname, layer, datatype):
    """Flattened rectangles (in nm) of the top cell(s) of a GDS file"""
    cells, scale = parse(fname, layer, datatype)
    used = {r[0] for c in cells.values() for r in c['refs']}
    rects = []
    for top in [c for c in cells if c not in used]:
        flatten(cells, top, lambda x, y: (x * scale, y * scale), rects)
    # Round to 0.01nm to remove floating-point noise
    return [tuple(round(v, 2) for v in r) for r in rects]

def _cover(rects, xs, ys):
    xi = {x: i for i, x in enumerate(xs)}
    yi = {y: i for i, y in enumerate(ys)}
    cells = set()
    for (x1, y1, x2, y2) in rects:
        for i in range(xi[x1], xi[x2]):
            for j in range(yi[y1], yi[y2]):
                cells.add((i, j))
    return cells

def _area(cells, xs, ys):
    return sum((xs[i + 1] - xs[i]) * (ys[j + 1] - ys[j]) for (i, j) in cells)

def compare(ref, test, layer, datatype):
    """Return (ref area, test area, xor area) of the flattened layer"""
    ra = flat(ref, layer, datatype)
    rb = flat(test, layer, datatype)
    xs = sorted({v for r in ra + rb for v in (r[0], r[2])})
    ys = sorted({v for r in ra + rb for v in (r[1], r[3])})
    ca = _cover(ra, xs, ys)
    cb = _cover(rb, xs, ys)
    return _area(ca, xs, ys), _area(cb, xs, ys), _area(ca ^ cb, xs, ys)
