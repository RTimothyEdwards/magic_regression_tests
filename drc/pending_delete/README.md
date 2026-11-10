# DRC pending list after deleting a cell

When a cell is changed, it is added to the list of cells waiting for the
background DRC check, unless it is already on the list.  Before magic
8.3.697, the last entry of the list was not compared, so a cell that was
already last (for example, the only cell on the list) was added again each
time it changed.  Deleting the cell removed only one of its entries, and the
next DRC check read the deleted cell and crashed.  This was reported with a
script that flattened a GDS cell, deleted the original with `cellname
delete`, and ran extraction;  the crash came when the interactive DRC ran.

The test requires 8.3.697.

## What the test does

In scmos, paint is added twice to cell `a`, so that `a` is queued for DRC
twice with no check in between.  Then another cell is loaded, `a` is
deleted with `cellname delete a -noprompt`, and `drc catchup` runs the
pending checks.  Magic must finish without crashing.
