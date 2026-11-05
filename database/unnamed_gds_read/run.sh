#!/bin/bash
#
# Reading GDS must not make the empty (UNNAMED) cell look like real content.
# See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.695

cd ${WORK}
echo "" > empty.rc
status=0

fail() {
    echo "  $1"
    status=1
}

# step <directory> <script>:  run a script in its own directory
step() {
    mkdir -p ${WORK}/$1
    cd ${WORK}/$1
    echo "" > empty.rc
    run_magic -T scmos -rcfile empty.rc ${TESTDIR}/$2.tcl < /dev/null > $2.log
    grep -q "^DONE" $2.log || fail "$1:  magic did not finish (see $1/$2.log)"
    cd ${WORK}
}

# A GDS file as vendors supply it:  the library name is not the name of a cell.
# (A file written by magic has the name of the top cell as its library name,
# and reading that loads the cell into the window.)

step make make
python3 - make/cella.gds foreign.gds <<'PYEOF'
import struct, sys
data = open(sys.argv[1], 'rb').read()
out, i = b'', 0
while i < len(data):
    length, kind = struct.unpack('>HH', data[i:i + 4])
    if length == 0:
        break
    rec = data[i:i + length]
    if kind == 0x0206:		# LIBNAME
        rec = struct.pack('>HH', 8, kind) + b'LIB\0'
    out += rec
    i += length
open(sys.argv[2], 'wb').write(out)
PYEOF
export GDSFILE=${WORK}/foreign.gds

# 1.  "writeall force" after reading GDS, as when installing a PDK
step read read
grep -q "^FLAGS .*modified" read/read.log && fail "gds read marked (UNNAMED) as modified"
grep -q "Writing '(UNNAMED)'" read/read.log && fail "writeall force tried to write (UNNAMED)"
grep -q "Must specify name" read/read.log && fail "writeall force asked for a name for (UNNAMED)"
[ -f read/cella.mag ] || fail "the cell read from GDS was not written"
grep -q "^TOP .*UNNAMED" read/read.log && fail "cellname list top includes empty (UNNAMED)"
grep -q "^TOP .*cella" read/read.log || fail "cellname list top is missing the cell"

# 2.  Building a GDS library from the top cells:  (UNNAMED) must not be in it,
# also after "cellname delete", which recreates it because it is in the window.
step library library
[ -f library/mylib.gds ] || fail "the library was not written"
if [ -f library/mylib.gds ]; then
    grep -qa "(UNNAMED)" library/mylib.gds && fail "the GDS library contains (UNNAMED)"
    grep -qa "cella" library/mylib.gds || fail "the GDS library is missing the cell"
fi
grep -q "default name" library/library.log && fail "gds write reported the default name"

# 3.  Reading GDS does not modify a cell that the user has loaded
step usercell usercell
grep -q "^USERFLAGS .*modified" usercell/usercell.log &&
	fail "gds read marked the loaded cell as modified"

# 4.  (UNNAMED) with contents is real
step painted painted
grep -q "^TOP .*UNNAMED" painted/painted.log ||
	fail "cellname list top is missing (UNNAMED) with paint in it"

# 5.  Top-level geometry in a CIF file goes in the edit cell, which is modified.
cat > toplevel.cif <<EOT
DS 1 1 1;
L CMF;
B 1200 1200 600 600;
DF;
L CMF;
B 1200 1200 3000 3000;
C 1;
E
EOT
export CIFFILE=${WORK}/toplevel
step cif cifread
grep -q "^FLAGS .*modified" cif/cifread.log || fail "cif read did not mark the edit cell as modified"
grep -q "^PAINT [1-9]" cif/cifread.log || fail "cif read did not add geometry to the edit cell"

finish ${status}
