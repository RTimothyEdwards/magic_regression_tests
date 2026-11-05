#!/usr/bin/env python3
#
# shuffle.py --- Write a copy of a .ext file with the records of the given
# kinds in a random order, keeping each kind of record in its own place.
# A negative seed reverses the order instead.
#
# Usage:  shuffle.py <in.ext> <out.ext> <seed> <kind> [<kind> ...]

import random
import sys

src, dst, seed = sys.argv[1], sys.argv[2], int(sys.argv[3])
kinds = sys.argv[4:]
rng = random.Random(seed)

lines = open(src).read().splitlines()
for kind in kinds:
    index = [i for i, l in enumerate(lines) if l.split()[:1] == [kind]]
    records = [lines[i] for i in index]
    if seed < 0:
        records.reverse()
    else:
        rng.shuffle(records)
    for i, l in zip(index, records):
        lines[i] = l
open(dst, 'w').write('\n'.join(lines) + '\n')
