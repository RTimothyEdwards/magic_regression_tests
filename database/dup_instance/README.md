# Coincident cell instances with different transforms

When a cell instance is placed, magic discards it if an instance of the
same cell is already there (for example, the same instance read twice
from a GDS file, or pasted twice).  Until commit 26da5adf (February 2023,
during version 8.3.373), the check compared only the cell and the bounding box, so
an instance mirrored or rotated so that it had the same bounding box as
another instance was also discarded.  Now the transforms (and array
parameters) must match as well.  (Notes in `~/devel/magic/dup_inst/`.)

## What the test does

An L-shaped cell `ell` (scmos metal1) is placed three times on the same
bounding box:  normally, mirrored about the y axis, and normally again (an
exact duplicate).  This is done in two ways:  with `getcell`, and by
reading a GDS file with three such references (written by `mkgds.py`).
In both cases, the saved top cell must have exactly two instances, the
normal one and the mirrored one.

With magic 8.3.373 (just before the fix), only one instance is left in
both cases.

Not covered:  the other places that call `DBCellFindDup()` (copying and
pasting selections, and cell copying in `DBcellcopy.c`).
