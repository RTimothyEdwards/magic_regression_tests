#!/usr/bin/env python3
#
# normalize.py --- Print a .res.ext file as a sorted list of records, with the
# two terminals of each resistor in sorted order, so that two files describing
# the same networks compare equal.
#
# Usage:  normalize.py <file.res.ext>

import sys

out = []
for line in open(sys.argv[1]):
    tok = line.split()
    if tok and tok[0] == 'resist':
        tok[1:3] = sorted(tok[1:3])
    out.append(' '.join(tok))
print('\n'.join(sorted(out)))
