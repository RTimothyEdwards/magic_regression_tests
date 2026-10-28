# GDS output when the vendor GDS file has been compressed

A read-only cell (read with `gds readonly true`, or a `.mag` file with the
GDS_FILE, GDS_START, and GDS_END properties) is written to GDS by copying
its data from the original GDS file.  If that file was later compressed,
so that GDS_FILE names `x.gds` but only `x.gds.gz` exists, magic failed
with "Can't find GDS file" and left the cell out of the output.  Since
magic 8.3.519 (commit df84a366, February 2025;  GitHub issue #366), it
looks for the compressed file as well.  (Notes in
`~/devel/magic/compression/`.)

## What the test does

In scmos:  write a small cell `blk` to `blk.gds`;  read it back as a
read-only cell, place it in `top`, and save both `.mag` files;  compress
`blk.gds` to `blk.gds.gz`;  then load `top` again and write `out.gds`.  The
test fails on any "Calma output error", and `check.py` checks that the
geometry of `blk` in `out.gds` is the same as in the original file.

With magic 8.3.518 (just before the fix), `blk` is left out of the
output with the error above.
