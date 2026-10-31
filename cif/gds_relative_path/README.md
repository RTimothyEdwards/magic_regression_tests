# GDS output with a GDS_FILE relative to the cell's directory

A read-only cell (with the GDS_FILE, GDS_START, and GDS_END properties) is
written to GDS by copying its data from the GDS file.  A relative GDS_FILE
was looked for only from the current directory and the cell search path,
not from the directory of the cell's own .mag file.  So a cell in a
subdirectory, placed with a path in its parent's `use` line (e.g., `use
sealring sealring_0 sealring`) and with GDS_FILE relative to that
subdirectory, failed with "Can't find GDS file" when the GDS was written
from the parent's directory.  (Found with the seal ring of the
gf180mcu_ocd_chipalooza chip, October 2026;  the problem was not new.)
Since magic 8.3.690, a relative GDS_FILE that is not found in the search
path is also looked for relative to the cell's directory.  The test
requires 8.3.690.

## What the test does

In scmos, with the directories `gds/`, `magic/`, and `magic/sub/`:  write
`gds/blk.gds`;  in `magic/sub/`, read it as a read-only cell (GDS_FILE is
then `../../gds/blk.gds`) and save `blk.mag`;  in `magic/`, place
`sub/blk` in `top` and save it;  then, in `magic/`, load `top` and write
GDS.  The test fails on any "Calma output error", and
`common/gds_same_layers.py` checks that the geometry of `blk` was copied.

With magic 8.3.689, `blk` is left out of the output.
