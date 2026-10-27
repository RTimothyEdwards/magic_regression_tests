#!/usr/bin/env python3
#
# gdsflat.py --- Compare the flattened geometry of GDS layer 68/20 in the
# top cells of two GDS files.
#
# Usage:  gdsflat.py <reference.gds> <test.gds>
# Prints:  "AREA ref=<area> test=<area> xor=<area>" (in square nm)
#
# See common/gdslib.py for what is supported.

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                '..', '..', 'common'))
from gdslib import compare

a, b, x = compare(sys.argv[1], sys.argv[2], 68, 20)
print('AREA ref=%g test=%g xor=%g' % (a, b, x))
