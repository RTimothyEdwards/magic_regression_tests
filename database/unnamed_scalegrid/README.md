# The empty (UNNAMED) cell and "scalegrid"

The startup file of a PDK that needs a finer grid runs "scalegrid", and this marked
every cell in the database as having a changed bounding box.  That includes the
empty (UNNAMED) cell that magic creates at startup, so a session in which nothing
had been done reported that (UNNAMED) needed saving:  "writeall" offered to write
it and "quit" warned that a cell had been modified.

The empty (UNNAMED) cell has no file and nothing to save, so it must not be
flagged.  (UNNAMED) with paint in it must still be offered, or the paint could be
lost.  A cell read from a file is unchanged, and still gets the flag.
