# GDS arrays (AREF)

Reading arrays (AREF records) from GDS:  rotated and reflected arrays,
arrays with a single row or column, and an array whose pitch is on a finer
grid than anything read before it.

Background:  Three fixes to reading AREF reference points in
`calmaElementSref()` (`calma/CalmaRdcl.c`) were made in February and March
2026 (notes in `~/devel/magic/Shep/missing_pin/` and
`~/devel/magic/Leo/gf_drc_error/`):

- f3404f67:  some tools write a bogus value for the array step in the
  direction in which the array has only one element.  Magic now ignores
  it, rather than letting it force an unnecessary rescaling of the grid.
- 8f684ad5:  when a reference point forced a (valid) grid rescaling, the
  points already read were not rescaled.
- 7d916725:  for an array with ANGLE 90 or 270, the coordinate to ignore
  for a single row or column is the other one.

## What the test does

`mkgds.py` writes a GDS file with a small asymmetric cell and nine arrays
of it (see the comments in `mkgds.py`).  Magic reads it with the sky130A
tech file, flattens the top cell, and writes the flattened cell out.
`check.py` flattens metal1 (68/20) in the original file (with
`common/gdslib.py`) and compares each array with magic's result.

The flattening is done in magic because an array that magic reads wrongly
may still be written back out exactly as it was read (with the bogus step
in the unused direction intact), so that the error shows only in magic's
own database:  in the original cases, as DRC errors where misplaced
contacts collided with other layout.  The
arrays use the convention that magic supports:  the steps are along the
axes of the (rotated) cell, so for ANGLE 90 the column step is along the
parent's y axis.

## Checking that the test catches the bugs

The original example was `digital_top-merged-HS.gds` (sky130, from Shep
Pitts):  its VIA2 to VIA4 power-post arrays have one column and a column
step of about -2^31.  Magic 8.3.606 read the left-hand column 4.08um to the
left of where it belongs.  With builds of the old versions:

- 8.3.606 (before f3404f67 and 8f684ad5):  `col1` and `row1` fail (the
  bogus step forces a rescaling) and `finegrid` fails (points read before
  the rescaling are not rescaled).
- 8.3.621 (before 7d916725):  `col1r90` and `row1r90` fail (the wrong
  coordinate is ignored for a rotated array), and so do `r270`, `col1`,
  and `row1` (the ignored coordinate was replaced by 0 instead of the
  origin's coordinate).

All cases pass with 8.3.622 and later.
