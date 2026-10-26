#!/bin/bash
#
# Cell file paths when cells are shared between directories.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

status=0
echo "" > ${WORK}/empty.rc

# mag <directory> <script text>:  run magic (scmos) in a directory
mag() {
    (cd ${WORK}/$1 && printf '%s\nquit -noprompt\n' "$2" > run.tcl && \
	run_magic -T scmos -rcfile ${WORK}/empty.rc run.tcl < /dev/null \
	> run.log 2>&1)
}

# check <description> <expected> <actual>
check() {
    if [ "$2" = "$3" ]; then
	echo "  ok: $1"
    else
	echo "  FAILED: $1"
	echo "      expected: $2"
	echo "      got:      $3"
	status=1
    fi
}

# uses <file>:  the "use" lines of a .mag file, one per line, sorted
uses() {
    grep '^use' $1 | sed 's/  */ /g' | sort
}

# Create a leaf cell <name> in directory <dir>
leaf() {
    mkdir -p ${WORK}/$1
    mag $1 "load $2
box 0 0 10 10
paint m1
save $2"
}

# Reload <cell> in <dir> and report the cells that could not be read
reload() {
    mag $1 "load $2
select top cell
expand
puts \"CELLS [lsort [cellname list allcells]]\""
    grep -c "couldn't be read\|not found\|Renaming cell" ${WORK}/$1/run.log
}

# ---------------------------------------------------------------------
# 1. The same file reached through two paths is one cell:  lib/inv is
#    used by mid/buf, and both are placed in top/top.
# ---------------------------------------------------------------------

echo "Case 1: same file through two paths"
leaf c1/lib inv
mkdir -p ${WORK}/c1/mid ${WORK}/c1/top
mag c1/mid "load buf
box 0 0 0 0
getcell ../lib/inv
save buf"
mag c1/top "load top
box 0 0 0 0
getcell ../mid/buf
box 100 0 100 0
getcell ../lib/inv
save top"
check "top.mag uses" "use buf buf_0 ../mid
use inv inv_0 ../lib" "$(uses ${WORK}/c1/top/top.mag)"
check "no rename on getcell" "0" "$(grep -c 'Renaming' ${WORK}/c1/top/run.log)"
check "reload finds all cells" "0" "$(reload c1/top top)"
check "one inv cell" "CELLS (UNNAMED) buf inv top" \
	"$(grep '^CELLS' ${WORK}/c1/top/run.log)"

# ---------------------------------------------------------------------
# 2. Saving a parent into another directory:  started in b/, a cell
#    using b/sub is saved as ../a/top.
# ---------------------------------------------------------------------

echo "Case 2: save a parent into another directory"
leaf c2/b sub
mkdir -p ${WORK}/c2/a
mag c2/b "load top
box 0 0 0 0
getcell sub
save ../a/top"
check "a/top.mag uses" "use sub sub_0 ../b" "$(uses ${WORK}/c2/a/top.mag)"
check "reload finds all cells" "0" "$(reload c2/a top)"

# ---------------------------------------------------------------------
# 3. Repairing a subcell that was not found:  a/top.mag uses sub with
#    no path, but sub is in b/.  "cellname filepath" sets the right
#    path, and the next expand must read it.
# ---------------------------------------------------------------------

echo "Case 3: repair a subcell that was not found"
leaf c3/b sub
mkdir -p ${WORK}/c3/a
cat > ${WORK}/c3/a/top.mag << 'EOM'
magic
tech scmos
timestamp 0
<< checkpaint >>
rect 0 0 10 10
use sub sub_0
timestamp 0
transform 1 0 0 0 1 0
box 0 0 10 10
<< end >>
EOM
mag c3/a "load top
select top cell
expand
cellname filepath sub ../b
select top cell
expand
puts \"SUBBOX [cellname list celldef sub] [box values]\"
save top"
check "a/top.mag uses after repair" "use sub sub_0 ../b" \
	"$(uses ${WORK}/c3/a/top.mag)"
check "reload finds all cells" "0" "$(reload c3/a top)"

# ---------------------------------------------------------------------
# 4. Changing directory with "cd":  started in a/, place b/sub after
#    "cd ../b", then "cd ../a" and save.  Also, expand a cell loaded
#    before a "cd".
# ---------------------------------------------------------------------

echo "Case 4: cd"
leaf c4/b sub
mkdir -p ${WORK}/c4/a
mag c4/a "load top
box 0 0 0 0
cd ../b
getcell sub
cd ../a
save top"
check "a/top.mag uses" "use sub sub_0 ../b" "$(uses ${WORK}/c4/a/top.mag)"
check "reload finds all cells" "0" "$(reload c4/a top)"

mkdir -p ${WORK}/c4/elsewhere
mag c4/a "load top -dereference
cd ../elsewhere
select top cell
expand
puts \"CELLS [lsort [cellname list allcells]]\"
save top"
check "expand after cd" "0" \
	"$(grep -c "couldn't be read" ${WORK}/c4/a/run.log)"
check "save after cd writes to the original directory" \
	"use sub sub_0 ../b" "$(uses ${WORK}/c4/a/top.mag)"

# ---------------------------------------------------------------------
# 5. A library reached through a symbolic link keeps the link name in
#    the path (proj/lib -> ../shared).
# ---------------------------------------------------------------------

echo "Case 5: symbolic link to a library"
leaf c5/shared inv
mkdir -p ${WORK}/c5/proj
ln -s ../shared ${WORK}/c5/proj/lib
mag c5/proj "load top
box 0 0 0 0
getcell lib/inv
save top"
check "proj/top.mag uses" "use inv inv_0 lib" "$(uses ${WORK}/c5/proj/top.mag)"

# ---------------------------------------------------------------------
# 6. Common layouts are written as before:  subcells in the same
#    directory, a subdirectory, a sibling directory, and a parent
#    loaded by absolute path.
# ---------------------------------------------------------------------

echo "Case 6: common layouts"
leaf c6/proj same
leaf c6/proj/sub below
leaf c6/sib beside
mag c6/proj "load top
box 0 0 0 0
getcell same
box 100 0 100 0
getcell sub/below
box 200 0 200 0
getcell ../sib/beside
save top"
check "proj/top.mag uses" "use below below_0 sub
use beside beside_0 ../sib
use same same_0" "$(uses ${WORK}/c6/proj/top.mag)"
mkdir -p ${WORK}/c6/other
mag c6/other "load ${WORK}/c6/proj/top
writeall force"
check "rewritten from another directory" "use below below_0 sub
use beside beside_0 ../sib
use same same_0" "$(uses ${WORK}/c6/proj/top.mag)"
check "reload after rewriting from another directory" "0" "$(reload c6/proj top)"

finish ${status}
