#!/usr/bin/env python3
#
# gen_vias.py --- Write vias.gds:  a via chain cell for each sky130 via
# level and number of cuts.  Each cell has a lower metal arm with port "l"
# at its far end, an upper metal arm with port "u" at its far end, and N
# cuts in one column where the arms overlap.  The arms are wide (16um) so
# that the metal resistance is small compared with the cuts, and the metal
# geometry is the same for every N, so that the difference in resistance
# between cells with different N depends only on the cut resistance.

import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                '..', '..', 'common'))
from gdslib import boundary, text, structure, library

# level:  (lower layer, upper layer, cut layer, cut size, cut spacing), nm
LEVELS = {
    'li_m1': (67, 68, 67, 170, 190),
    'm1_m2': (68, 69, 68, 150, 170),
    'm2_m3': (69, 70, 69, 200, 200),
    'm3_m4': (70, 71, 70, 200, 200),
    'm4_m5': (71, 72, 71, 800, 800),
}
CUTS = (1, 2, 4, 8)

ARM = 20000	# arm length
WIDTH = 16000	# arm width
OVER = 3000	# length of the overlap of the two arms

def via_chain(level, ncuts):
    lower, upper, cut, size, space = LEVELS[level]
    body = b''
    # Lower arm, and upper arm overlapping it by OVER
    body += boundary(0, 0, ARM + OVER, WIDTH, lower, 20)
    body += boundary(ARM, 0, 2 * ARM + OVER, WIDTH, upper, 20)
    # Cuts in a column centered in the overlap
    pitch = size + space
    total = ncuts * size + (ncuts - 1) * space
    x0 = ARM + (OVER - size) // 2
    y0 = (WIDTH - total) // 2
    for k in range(ncuts):
        body += boundary(x0, y0 + k * pitch, x0 + size, y0 + k * pitch + size,
                cut, 44)
    # Ports:  1um pin squares at the far ends of the arms
    body += boundary(0, (WIDTH - 1000) // 2, 1000, (WIDTH + 1000) // 2, lower, 16)
    body += text(500, WIDTH // 2, 'l', lower, 16)
    end = 2 * ARM + OVER
    body += boundary(end - 1000, (WIDTH - 1000) // 2, end, (WIDTH + 1000) // 2,
            upper, 16)
    body += text(end - 500, WIDTH // 2, 'u', upper, 16)
    return structure('vc_%s_n%d' % (level, ncuts), body)

cells = [via_chain(lv, n) for lv in LEVELS for n in CUTS]
with open(sys.argv[1] if len(sys.argv) > 1 else 'vias.gds', 'wb') as f:
    f.write(library(cells))
