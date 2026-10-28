# FIXED_BBOX and mask hints under "scalegrid" and "move origin"

Properties that hold layout coordinates (FIXED_BBOX and the MASKHINTS_*
mask hints) must be scaled and moved along with the layout:

- Before commit cd80d38d (February 2025), `scalegrid` scaled FIXED_BBOX
  twice (once by the old code and once by the code added for mask hints),
  so `scalegrid 1 2` multiplied it by 4.
- Since mask hints became a "plane" type property (commit 7bdd9e1d, March
  2026), `dbScaleProp()` and `dbMoveProp()` used the scale factors or
  offsets before setting them, so `scalegrid` crashed (division by zero)
  or wiped the mask hints, and `move origin` moved them by garbage.  Fixed
  in magic 8.3.689.  The test therefore requires 8.3.689.

## What the test does

In scmos, a cell gets a FIXED_BBOX and a MASKHINTS_m2 property with two
rectangles.  After `scalegrid 1 2`, the paint, FIXED_BBOX, and mask hints
must all be exactly twice their values;  after `move origin e 10`,
FIXED_BBOX and the mask hints must have moved exactly as far as the paint.
Mask hints are compared as a set of rectangles (their order is not
significant).

With magic 8.3.688, magic crashes in `scalegrid`.  With 8.3.517 (just
before cd80d38d), FIXED_BBOX is multiplied by 4, and `move origin` loses
one of the two mask hint rectangles.
