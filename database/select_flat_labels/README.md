# Label names after flattening a selection with "select flat"

Flattening a cell in place with `select top cell;  select pick;  select
flat;  select keep` prefixed every label with the name of the instance
it came from, including labels in the top cell itself, which got the
prefix "Topmost cell in the window/".  Fixed in commit 083c0c10 (March
2022).  (Notes in `~/devel/magic/Simon/tia_core/`.)

## What the test does

In scmos, the top cell has a label "A" and an instance sub_0 of a cell
with a label "B".  After flattening as above, the top cell must have
exactly two labels:  "A" (unchanged) and "B" prefixed with "sub_0" (the
hierarchy separator, "/" in 2022 and "." now, is not checked).

With magic 8.3.275 (just before the fix, built with `-fpermissive`), the
labels are "A", "Topmost cell in the window/A", and "Topmost cell in the
window/sub_0/B".

## Crash in "select flat" (fixed in 8.3.690)

The 2022 fix made the label search skip the path name of a top level
window, but then `dbCellLabelSrFunc()` (`database/DBcellsrch.c`) still
restored the path using a pointer that had not been set in that case,
writing through an uninitialized pointer.  This test does exactly that
(`select flat` searches from the top level window), so it crashed on some
machines (it was first seen on GitHub;  valgrind shows the uninitialized
pointer everywhere).  Fixed in magic 8.3.690, so the test requires 8.3.690.
