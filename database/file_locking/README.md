# File locking when reading cells

Magic takes an advisory lock (`fcntl`) on each cell file it reads, so that
a second magic process reading the same files gets them read-only.  The
`locking` command turns this off.  This test checks the state of each cell
(`cellname list writeable`) after reading a small hierarchy, a top cell
with three subcells, in the built-in scmos technology.

The cases are:

- No other process: every cell is writeable, and locking is enabled by
  default.
- Another magic process holds the locks: every cell is read-only, with the
  "already locked" message.  Asking to make the top cell writeable reports
  that an advisory lock is held.  The other process changes and saves one
  subcell before the check, so its lock must be taken again after the
  file is rewritten.
- The same, but with `locking disable`:  the locks are ignored and every
  cell is writeable.
- After the other process exits:  every cell is writeable again.
- One subcell file without write permission:  that cell, and only that
  cell, is read-only, with or without locking, and magic prints the "not
  writeable" warning.  Asking to make it writeable must not report a lock.
  This case is skipped when running as root.

Before 8.3.705, `dbReadOpen()` read `is_locked` when locking was disabled,
but nothing had set it, so a cell could be made read-only at random.
Whether that happens depends on what was on the stack, and an ordinary run
usually passes.  Run with `VALGRIND=1` to detect it reliably:  valgrind
reports a conditional jump on an uninitialised value at `DBio.c:1622`.

Also before 8.3.705, with locking enabled, a file that could not be opened
for writing was reported as locked by another process:  there was no "not
writeable" warning, and "cellname writeable" said that an advisory lock
was held.
