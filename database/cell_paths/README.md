# Cell file paths when cells are shared between directories

From GitHub pull request #567, which reported four problems with using
cells from other directories.  The fixes in magic are different from the
ones in the pull request (which resolved symbolic links when writing
paths and made every cell file path absolute).

Each case builds a small project of cells in several directories with the
scmos technology, in separate magic sessions started in different
directories, then checks the "use" lines that are written and that the
saved layout can be reloaded with every subcell found.

1. **The same file reached through two paths is one cell.**  `lib/inv` is
   used by `mid/buf`, and both are placed in `top/top`.  Reading `buf`
   records `inv` as `../mid/../lib/inv`; "getcell ../lib/inv" used to
   compare the paths as strings and create a renamed copy `inv_a`.
2. **Saving a parent into another directory.**  Started in `b/`, a cell
   using `b/sub` is saved as `../a/top`; the "use" line must say `../b`.
3. **Repairing a subcell that was not found.**  `a/top.mag` uses `sub`
   with no path; after `cellname filepath sub ../b`, the next expand
   must read it.
4. **Changing directory.**  Started in `a/`, `cd ../b`, `getcell sub`,
   `cd ../a`, `save`:  the "use" line must say `../b`.  A cell loaded
   before a `cd` must still be expandable and saved to its original
   location afterward.
5. **Symbolic links are kept.**  `proj/lib` is a link to `../shared`;
   the "use" line must say `lib`, not the resolved directory.
6. **Common layouts are unchanged:**  subcells in the same directory, a
   subdirectory, and a sibling directory, and a parent loaded by absolute
   path from another directory and written back.  The relative paths must
   stay relative (they used to become "~/..." paths when the project is
   inside the home directory).
