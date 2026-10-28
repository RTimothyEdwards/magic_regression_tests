# Cell bounding box with label text extending outside the paint

When a cell whose label text extends outside its paint was read from its
file with `getcell`, its bounding box included the label text, so for
example `select top cell` selected an area much larger than the layout.
`DBBoundCellPlane()` returned the extended bounding box (with the label
text) where the plain bounding box was needed.  Fixed in commit e04307c0
(August 2025).  (Notes in `~/devel/magic/bbox_labels/`.)

## What the test does

In scmos:  `make.tcl` makes a cell with metal1 from (0, 0) to (71, 78) and
a large rendered label, and saves it.  `bbox.tcl`, in a new session,
places the cell at (-50, 144) with `getcell` and selects the top cell.  The
selected area must be (-50, 144) to (21, 222).

The cell has to be read from its file:  if it is made and placed in the
same session, the bounding box was correct even before the fix.  With
magic 8.3.545 (just before the fix), the selected area is (-5486, -458) to
(5457, 584).
