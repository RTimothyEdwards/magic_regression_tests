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

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                '..', '..', 'common'))
from gdslib import boundary, sref, aref, structure, library

cells = [
    structure('A', boundary(0, 0, 1200, 480) + boundary(0, 480, 480, 1680)),
    structure('B', boundary(2400, 0, 2640, 240) + sref('A', 0, 0, mag=2)),
    structure('D', boundary(0, 0, 70, 30) + boundary(130, 10, 150, 90)),
    structure('TOP',
            sref('D', -2000, -2000, mag=1.5) +
            sref('A', 0, 0, mag=1.5) +
            sref('A', 6000, 0, mag=1.5, angle=90, reflect=True) +
            sref('B', 0, 8000, mag=1.5) +
            sref('B', 12000, 0, mag=0.5) +
            aref('A', 2, 3, [(12000, 6000), (14000, 6000), (12000, 9000)], mag=0.5) +
            sref('A', 18000, 0, mag=1.0 / 3.0) +
            sref('A', 22000, 0) +
            boundary(-3000, -3000, -2900, -2900)),
]

open(sys.argv[1], 'wb').write(library(cells, 'MAGTEST'))
