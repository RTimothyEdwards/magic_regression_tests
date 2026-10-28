# Labels must stay attached when part of the shape is erased

GitHub issue #305:  erasing a small part of a shape that has a label
covering it made the label lose its attachment (its type became "space").
Since commit ca99d0b7 (May 2024, magic 8.3.478), the label area is clipped
back so that it stays on the remaining material.

## What the test does

In scmos, a 20x20 metal1 square gets a label covering the whole square,
and then part of the square is erased:  the northeast corner, the
southwest corner, or a strip along the top.  The label must still be
attached to metal1, and its area must lie entirely on metal1.  How the
label area is clipped is not checked.

With magic from just before the fix (also numbered 8.3.478), the label
becomes "space" in all three cases.
