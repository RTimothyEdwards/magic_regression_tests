# Reading GDS with the empty (UNNAMED) cell in the window

At the end of a GDS or CIF read, the edit cell was always marked as modified.
Top-level geometry in a CIF file goes into the edit cell, but everything in a GDS
file is in a structure, so a GDS read does not change it.  If the library name in
the file is the name of a cell, then that cell is loaded and hides the problem, but
in a vendor's GDS file it usually is not, and the edit cell is still (UNNAMED).

An installation script doing "gds read" and "writeall force" then reported:

    Writing '(UNNAMED)'
    Must specify name for cell (UNNAMED).
    Can't write file named '(UNNAMED)'

Separately, `cellname list top` included the empty (UNNAMED) cell.  Deleting it
does not help, because it is recreated if it is in a window.  A script that builds
a library from the top cells would place it in the library, and the GDS output
then had a structure named `(UNNAMED)`.

Cases:

1. `gds read` + `writeall force`:  no attempt to write (UNNAMED), and it is not
   in `cellname list top`.
2. The steps that make a GDS library:  no (UNNAMED) in the output.
3. A cell loaded by the user is not modified by a GDS read.
4. (UNNAMED) with paint in it is a real cell, and is listed.
5. A CIF file with top-level geometry still modifies the edit cell.
