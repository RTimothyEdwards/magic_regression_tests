# Parents of a cell with a stale timestamp

When a cell's timestamp differs from the one recorded in one of its parents,
magic verifies the cell's bounding box.  This used to flag **every** parent of
the cell as having a changed bounding box, whether or not it had changed, and
whether or not that parent had the old timestamp.  Correct cells were needlessly
rewritten, and "writeall" tried to write read-only library cells:

    File .../GF_NI_FILL10_1.mag is read_only and cannot be written

This was found in a chip padframe after a PDK update.  A local copy of the PDK
cell `GF_NI_FILL10_1` and the PDK cell itself both use `POLY_SUB_FILL_1`, and
the local copy recorded its old timestamp.

Parents sharing one child, `leaf`.  The first three are correct and "writeall"
must not offer to write them or change their files:

- `readonlyparent` has a read-only file.
- `vendorparent` is writeable and has a `GDS_FILE` property.
- `cleanparent` is an ordinary writeable cell.

The other two must be written, and record the correct values:

- `staleparent` has an old timestamp.
- `staleboxparent` has an old timestamp and an old bounding box.

The test runs with the stale uses both first and last in the top cell, because
the mismatch is found in different places in the code:  when the child is read,
or when the stale use is read after the child's timestamp is already known.

A mismatch also forces a DRC recheck, but only of the two stale parents and the
cells above them.  The child and the correct parents are not rechecked:  a parent
with the new timestamp has already seen this version of the child, and a vendor
cell is trusted to be clean.  Otherwise a DRC run would rewrite correct cells.  To
see this, the DRC is left off and the cells are written, so that check areas that
were requested appear as `<< checkpaint >>` in the files.

Then two real edits to a child, with no stale information in the files, must
still update the parent:  painting beyond the bounding box (the parent records
a new box and timestamp) and painting inside it (a new timestamp only).
