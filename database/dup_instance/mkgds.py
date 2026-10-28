#!/usr/bin/env python3
#
# mkgds.py --- Write the GDS file for the dup_instance test.
#
# Usage:  mkgds.py <ell.gds> <out.gds>
#
# Copies the layer, datatype, and boxes of structure "ell" from <ell.gds>
# (written by magic), and writes <out.gds> with the structure "ell" and a
# top structure "top_gds" with three references to it at the same place:
# unmirrored, mirrored about the y axis (moved so that the bounding box is
# the same), and unmirrored again (an exact duplicate).

import os
import struct
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                '..', '..', 'common'))
from gdslib import boundary, sref, structure, library, gds_real

def read_boxes(fname):
    data = open(fname, 'rb').read()
    boxes = []
    i = 0
    while i < len(data):
        ln, rt = struct.unpack('>HB', data[i:i + 3])
        if ln < 4:
            break
        body = data[i + 4:i + ln]
        if rt == 0x03:
            nm = gds_real(body[8:16]) / 1e-9
        elif rt == 0x0d:
            layer = struct.unpack('>h', body)[0]
        elif rt == 0x0e:
            dtype = struct.unpack('>h', body)[0]
        elif rt == 0x10:
            xy = struct.unpack('>%di' % (len(body) // 4), body)
            xs, ys = xy[0::2], xy[1::2]
            boxes.append((layer, dtype, min(xs), min(ys), max(xs), max(ys)))
        i += ln
    return boxes, nm

boxes, nm = read_boxes(sys.argv[1])
if abs(nm - 1) > 1e-6:
    raise SystemExit('unexpected GDS units in %s' % sys.argv[1])
body = b''.join(boundary(x1, y1, x2, y2, layer=l, datatype=d)
                for (l, d, x1, y1, x2, y2) in boxes)
width = max(b[4] for b in boxes) - min(b[2] for b in boxes)
cells = [
    structure('ell', body),
    structure('top_gds',
              sref('ell', 0, 0) +
              # Mirrored about the y axis (reflect, then rotate 180) and
              # moved right by the width, so the bounding box is the same
              sref('ell', width, 0, angle=180, reflect=True) +
              sref('ell', 0, 0)),
]
open(sys.argv[2], 'wb').write(library(cells, 'DUPTEST'))
