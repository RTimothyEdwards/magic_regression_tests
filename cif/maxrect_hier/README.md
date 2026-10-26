# Hierarchical output of "maxrect external" layers

Found with the IHP sg13cmos5l seal ring:  SEALBOUND is generated with
`maxrect external` from the seal ring layer, and the seal ring is split
across corner and side subcells.  The GDS output had a SEALBOUND
rectangle in each subcell (the bounding box of that subcell's piece of the
seal ring) and a few small pieces in the parent near the corners, but
not the rectangle covering the whole chip.

Magic computes the hierarchical part of a cell's CIF only in "interaction
areas" where subcells come within the CIF radius of each other, which
assumes the result at any point depends only on geometry nearby.  The
result of `maxrect` depends on the whole connected region, which can span
any number of subcells, so it has to be computed over the whole cell.

## What the test does

Using a copy of the sky130A tech file with an added output layer MAXM1
(GDS layer 200/0, `maxrect external` of metal1), it builds a 200um x 202um
ring of metal1 out of four subcells, writes it as GDS both hierarchically
and flattened, flattens the MAXM1 shapes from each file, and checks that
both are the same single solid rectangle.

Without the fix, the hierarchical file has MAXM1 only as the bounding
boxes of the four subcells' strips (about 2% of the area).
