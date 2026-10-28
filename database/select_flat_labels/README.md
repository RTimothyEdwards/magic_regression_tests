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
