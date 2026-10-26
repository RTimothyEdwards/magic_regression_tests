# Very long cell use names

GitHub issue #564 (test case in `/home/tim/devel/magic/Mike/`):  a design
from LibreLane had cell use names (`cu_id`) more than 1024 characters
long, and magic crashed when saving it.  `dbWriteCellFunc()` wrote the
"use" line into a fixed 1024-byte buffer, and `DBPathSubstitute()` could
add the cell's path to the same buffer.  Reading such a file also failed:
use names were truncated to 1023 characters (which can make two use names
identical), and a "use" line longer than the 2048-byte line buffer made
the file unreadable.

The test, using the built-in scmos technology:

1. saves a cell with two uses whose 1500-character names differ only in
   the last character (the longest name the `identify` command accepts,
   since a command is limited to 2048 characters);
2. reads that file back and saves it again, checking that both names are
   preserved;
3. reads files with use names of 2035 to 2038 characters, which put the
   length of the "use" line on either side of the 2048-byte line buffer,
   and of 5000 and 20000 characters.

Paths longer than 1023 characters in a "use" line are still not
supported when reading (a warning is printed and the path is ignored).
