# Painting over split (non-Manhattan) tiles

Painting a box that partly overlaps split (triangular) tiles has to split
the triangles along the edges of the box and merge the pieces back into
the plane.  Two bugs in this code (`DBPaintPlane0()` in
`database/DBpaint.c`) have been found and fixed:

- **corner** (fixed in commit 4ccd5a78, January 2026):  painting a box
  inside the corner of a triangle
  (`box values 0 0 20 20; splitpaint sw m1; box values 8 8 16 16; paint m1`)
  left a stripe of metal1 along the top of the box running off to
  infinity, and "undo" then crashed.  This came from two lines merging a
  split tile to the right, which had been commented out and were put back
  in August 2025;  the right side of the tile is still to be visited by
  the search, so it must not be merged yet.  (Notes in
  `~/devel/magic/split_tile_crash/`.)
- **stripe** (fixed in commit 8ed73944, August 2025):  painting a box over
  a rectangle with a triangle on each side, covering the triangles only
  partly, left the right side of the area unpainted and broke the
  maximum horizontal stripes rule.  This was found in the sky130 fill
  generator.  (Notes and `paint_test.mag` in
  `~/devel/magic/skipped_tile/gds/`.)

## What the test does

For each case (`corner`, `stripe`, `stripe_low`, `diagonal`), `paint.tcl`
draws the triangles and rectangles in scmos, saves the cell, paints a box,
saves it again, does "undo", and saves it a third time.  `check.py` reads
the shapes from the three .mag files and checks that:

- after the paint, each layer covers exactly what it covered before plus
  the box (on the painted layer);
- after the undo, each layer covers exactly what it covered before;
- no shape has huge coordinates (a tile running off to infinity).

Areas are compared exactly:  each unit square is split along both
diagonals into four quarters, and the quarters covered by each shape are
counted.

## Checking that the test catches the bugs

Built from the commits just before each fix (configured with `--prefix`
so that the old version really is the one run;  see the note in
`TODO.md`):

- 8.3.534 (before 8ed73944):  the `stripe` case fails, with 1000 square
  units of the box left unpainted on the right side.
- 8.3.587 (before 4ccd5a78):  the `corner` case fails:  the saved layout
  has a metal1 rectangle from x=8 to x=1073741820, and magic crashes on
  "undo".

Both pass with later versions.
