# Repeated "copy" of a cell instance followed by "undo"

Copying a cell instance several times and then undoing removed only the
last copy:  later "undo" commands moved the box but left the copies.  The
copy kept the original instance's name and the original instance was
renamed, so undo records referred to the wrong instance.  Fixed in commit
dde71449 (March 2025), which makes the names in the selection unique
before the copy.  (Notes in `~/devel/magic/Mark/copy_undo_issue/`.)

## What the test does

In scmos, a cell is placed once and copied four times with `copy e 20`;
then `undo` is done three times.  There must be five instances after the
copies and two (the original at x = 0 and the first copy at x = 20) after
the undos.

With magic 8.3.522 (just before the fix), four instances are left after
the undos.

Note:  `select` is itself undoable, so a `select` between the copies and
the undos would make the first `undo` undo the selection instead.
