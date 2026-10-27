#!/usr/bin/env python3
#
# mkgds.py --- Write the GDS file for the gds_magnification test.
#
# Usage:  mkgds.py <file.gds>
#
# All shapes are on GDS layer 68/20 (sky130 metal1).  Units are 1nm.
#
#   A    An "L" shape (not symmetric, so that rotations and reflections
#        can be seen).
#   B    A box, and an instance of A magnified by 2.
#   D    A box with dimensions that are off-grid when magnified by 1.5.
#   TOP  Instances of A, B, and D with various magnifications:
#          D x1.5 (the magic grid must be rescaled while reading D)
#          A x1.5, twice (once rotated and reflected)
#          B x1.5 (A inside is then magnified by 3)
#          B x0.5 (A inside is then not magnified)
#          A x0.5 in a 2 x 3 array
#          A x1/3
#          A unmagnified

import struct
import sys

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

def string(s):
    return s.encode()

STAMP = i2(126, 1, 1, 0, 0, 0) * 2

def boundary(x1, y1, x2, y2):
    return (rec(0x08, 0) + rec(0x0d, 2, i2(68)) + rec(0x0e, 2, i2(20)) +
            rec(0x10, 3, i4(x1, y1, x2, y1, x2, y2, x1, y2, x1, y1)) +
            rec(0x11, 0))

def strans(mag, angle, reflect):
    if mag == 1 and angle == 0 and not reflect:
        return b''
    out = rec(0x1a, 1, struct.pack('>H', 0x8000 if reflect else 0))
    if mag != 1:
        out += rec(0x1b, 5, real8(mag))
    if angle != 0:
        out += rec(0x1c, 5, real8(angle))
    return out

def sref(name, x, y, mag=1, angle=0, reflect=False):
    return (rec(0x0a, 0) + rec(0x12, 6, string(name)) +
            strans(mag, angle, reflect) + rec(0x10, 3, i4(x, y)) + rec(0x11, 0))

def aref(name, x, y, cols, rows, dx, dy, mag=1):
    return (rec(0x0b, 0) + rec(0x12, 6, string(name)) + strans(mag, 0, False) +
            rec(0x13, 2, i2(cols, rows)) +
            rec(0x10, 3, i4(x, y, x + cols * dx, y, x, y + rows * dy)) +
            rec(0x11, 0))

def struct_(name, body):
    return (rec(0x05, 2, STAMP) + rec(0x06, 6, string(name)) + body +
            rec(0x07, 0))

cells = [
    struct_('A', boundary(0, 0, 1200, 480) + boundary(0, 480, 480, 1680)),
    struct_('B', boundary(2400, 0, 2640, 240) + sref('A', 0, 0, mag=2)),
    struct_('D', boundary(0, 0, 70, 30) + boundary(130, 10, 150, 90)),
    struct_('TOP',
            sref('D', -2000, -2000, mag=1.5) +
            sref('A', 0, 0, mag=1.5) +
            sref('A', 6000, 0, mag=1.5, angle=90, reflect=True) +
            sref('B', 0, 8000, mag=1.5) +
            sref('B', 12000, 0, mag=0.5) +
            aref('A', 12000, 6000, 2, 3, 1000, 1000, mag=0.5) +
            sref('A', 18000, 0, mag=1.0 / 3.0) +
            sref('A', 22000, 0) +
            boundary(-3000, -3000, -2900, -2900)),
]

data = (rec(0x00, 2, i2(600)) + rec(0x01, 2, STAMP) +
        rec(0x02, 6, string('MAGTEST')) +
        rec(0x03, 5, real8(0.001) + real8(1e-9)) +
        b''.join(cells) + rec(0x04, 0))
open(sys.argv[1], 'wb').write(data)
