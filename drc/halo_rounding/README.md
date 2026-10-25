# DRC halo rounding

Magic checks DRC in areas ("chunks") and looks at edges within a halo
around each area, where the halo is the largest rule distance.  The halo
was computed by converting the largest rule distance from tech file units
with integer division, which rounds down, while rule distances themselves
are rounded up.  With a 240 rule at scalefactor 50 (4.8 lambda), the halo
was 4 lambda (40 internal units on a 5nm grid) for a 48-unit rule.  So an
error caused by an edge more than 40 but less than 48 units outside an
area was never found.

In a full rule deck this only matters when the largest rule distance is
not a multiple of the scalefactor, but it then gives false negatives.
The fix rounds the halo up.

## What the test does

Using a gf180mcuD tech file whose only DRC rule is `spacing pc pc 240`, the
test places a pair of poly contacts with a corner-to-corner violation
(offset 46, 3 units) in its own cell at each of x = 0, 2, ... 1598, and
checks that the error is found in every cell.  Without the fix, the error
is missed at x = 366 and x = 1000 to 1006.
