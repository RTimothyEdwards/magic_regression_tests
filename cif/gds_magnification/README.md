# GDS instances with magnification

Found with a Chipalooza project (slot_4 of challenge_ihp_1), which places
a cell of artwork on the top metal with a magnification of 1.5.  Magic
rounded the magnification to an integer and put it in the cell use's
transform, but a magic cell use transform cannot contain a scale factor
(most of magic assumes that it does not), so the artwork came out the
wrong size, which broke the fill pattern generation.

Magic now reads a magnified instance as an instance of a magnified copy
of the cell, named after the cell and the magnification (e.g., `A_mag1p5`).
The copy is read from the GDS with the input scale multiplied by the
magnification, and its own subcells are magnified copies, so nested
magnifications multiply.  The copy has the property `GDS_MAG_SOURCE`
naming the original cell.  When the GDS of a read-only cell (`gds
readonly true`) is copied verbatim to the output, its instances are
still magnified instances of the original cells, so the writer outputs
the original cells in place of the copies.

## What the test does

`mkgds.py` writes a GDS file in which the top cell has instances of three
cells with magnifications 1.5 (twice, once rotated and reflected), 0.5 (in
an array), 1/3, and 1, a cell with a nested magnification (1.5 times 2),
another (0.5 times 2, so the innermost cell is not magnified), and a cell
whose geometry falls off the magic grid when magnified (so the grid is
rescaled while reading the copy).  Magic reads the file and writes it out
again, both normally and with `gds readonly true`.  The test checks:

- the geometry of each output file, flattened by `gdsflat.py` (which
  implements the GDS magnification itself), is the same as that of the
  original file;
- the magnified copies made are exactly the expected ones (one per cell
  and magnification), each with `GDS_MAG_SOURCE` set, and the two
  instances magnified by 1.5 share one copy;
- no cell use transform in the saved .mag files is scaled;
- the read-only output contains the original cells and no copies.

Without the fix, the normal output has the wrong geometry (and scaled
cell use transforms in the .mag files).
