#!/usr/bin/env python3
#
# mkgds.py --- Write the GDS file for the gds_aref test.
#
# Usage:  mkgds.py <file.gds>
#
# Cell "A" is an "L" shape on layer 68/20 (sky130 metal1), not symmetric,
# so that rotations and reflections can be seen.  Units are 1nm.  The top
# cell has one array (AREF) of "A" for each case, 20um apart.  Magic
# represents an array in the coordinates of the cell, so for an AREF with
# ANGLE 90, the column step is along the y axis of the parent.
#
#   finegrid  3 x 2 array whose pitch (2005nm) is on a finer grid than any
#             coordinate read before it, so that magic must rescale its
#             grid while reading the array's points.  This is the first
#             array in the file.
#   plain     3 x 2 array, no rotation
#   r90       3 x 2 array, ANGLE 90
#   r270      3 x 2 array, ANGLE 270
#   m90       3 x 2 array, reflected and ANGLE 90
#   col1      1 x 4 array (one column), with a bogus, huge, off-grid X value
#             for the (unused) column step
#   row1      4 x 1 array (one row), with a bogus Y value for the (unused)
#             row step
#   col1r90   1 x 4 array with ANGLE 90, with a bogus Y value for the
#             (unused) column step, which is along the y axis
#   row1r90   4 x 1 array with ANGLE 90, with a bogus X value for the
#             (unused) row step, which is along the x axis

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                '..', '..', 'common'))
from gdslib import boundary, aref, structure, library

BOGUS = -2147480001	# Huge and not on the 5nm grid

def array(x, y, cols, rows, cstep, rstep, angle=0, reflect=False,
          bogus_col=None, bogus_row=None):
    """AREF of "A" at (x, y).  cstep and rstep are the column and row
    steps (in the parent's coordinates).  bogus_col or bogus_row replaces
    the x ('x') or y ('y') value of the point for the unused step."""
    p2 = [x + cols * cstep[0], y + cols * cstep[1]]
    p3 = [x + rows * rstep[0], y + rows * rstep[1]]
    if bogus_col == 'x':
        p2[0] = BOGUS
    elif bogus_col == 'y':
        p2[1] = BOGUS
    if bogus_row == 'x':
        p3[0] = BOGUS
    elif bogus_row == 'y':
        p3[1] = BOGUS
    return aref('A', cols, rows, [(x, y), tuple(p2), tuple(p3)],
                angle=angle, reflect=reflect)

top = (
    array(0, 0, 3, 2, (2005, 0), (0, 3000)) +				# finegrid
    array(20000, 0, 3, 2, (2000, 0), (0, 3000)) +			# plain
    array(40000, 0, 3, 2, (0, 2000), (-3000, 0), angle=90) +		# r90
    array(60000, 0, 3, 2, (0, -2000), (3000, 0), angle=270) +		# r270
    array(80000, 0, 3, 2, (0, 2000), (3000, 0), angle=90,
          reflect=True) +						# m90
    array(0, 20000, 1, 4, (2000, 0), (0, 3000), bogus_col='x') +	# col1
    array(20000, 20000, 4, 1, (2000, 0), (0, 3000), bogus_row='y') +	# row1
    array(40000, 20000, 1, 4, (0, 2000), (-3000, 0), angle=90,
          bogus_col='y') +						# col1r90
    array(60000, 20000, 4, 1, (0, 2000), (-3000, 0), angle=90,
          bogus_row='x')						# row1r90
)

cells = [
    structure('A', boundary(0, 0, 1200, 480) + boundary(0, 480, 480, 1680)),
    structure('TOP', top),
]
open(sys.argv[1], 'wb').write(library(cells, 'AREFTEST'))
