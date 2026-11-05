# When a DRC check makes a cell's file out of date

The DRC check and error planes are saved in a cell's file, but running a check
should not by itself mark the cell as modified.  The file is out of date only
if the check clears `checkpaint` that the file contains, or finds different
errors from the ones the file contains.  Rewriting a file in any other case
produces an identical file.

| Cell | Check finds | Written? |
|---|---|---|
| clean, writeable | no errors | no |
| writeable, `checkpaint` in the file | no errors | yes, without `checkpaint` |
| writeable | an error not in the file | yes, with the error |
| either of the last two, checked again | the same as the file | no |
| saved with `checkpaint` pending, checked later in the session | no errors | yes |
| read-only, clean or with an error not in the file | either | no |
| vendor (`GDS_FILE`), with an error not in the file | an error | no |
| read-only, `checkpaint` in the file | no errors | reports that it cannot be written |

A read-only file with `checkpaint` is a mistake in the PDK views, so magic checks
the cell, marks it as modified, and keeps reporting that it cannot be written.

Edits made with the DRC off are still recorded:  `paint` and `erase` must both
save `checkpaint`.  A cell read from GDS is different, and depends only on
`gds drccheck`, not on the DRC state.  This is how a PDK gets views that are clean
by design, so with `gds drccheck no` a read cell must have no `checkpaint`.

The last case covers a stale timestamp:  `mid` has an old timestamp for `leaf`
and must be written.  The recheck also propagates up to `top`, whose information
is all correct and which has no new errors, so it must not be written.
