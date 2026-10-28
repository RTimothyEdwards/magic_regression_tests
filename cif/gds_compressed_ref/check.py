#!/usr/bin/env python3
#
# check.py --- Compare the geometry of the original blk.gds with out.gds.
#
# Usage:  check.py <blk_orig.gds> <out.gds>
#
# Compares every layer and datatype found in the original file.

import os
import struct
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                '..', '..', 'common'))
import gdslib

def layers(fname):
    data = open(fname, 'rb').read()
    found = set()
    i = 0
    while i < len(data):
        ln, rt = struct.unpack('>HB', data[i:i + 3])
        if ln < 4:
            break
        if rt == 0x0d:
            layer = struct.unpack('>h', data[i + 4:i + 6])[0]
        elif rt == 0x0e:
            found.add((layer, struct.unpack('>h', data[i + 4:i + 6])[0]))
        i += ln
    return sorted(found)

status = 0
for layer, dtype in layers(sys.argv[1]):
    ref, test, xor = gdslib.compare(sys.argv[1], sys.argv[2], layer, dtype)
    print('layer %d/%d:  %s' % (layer, dtype, 'same' if xor == 0 and ref > 0
          else 'differs (area %g, expected %g)' % (test, ref)))
    if xor != 0 or ref == 0:
        status = 1
sys.exit(status)
