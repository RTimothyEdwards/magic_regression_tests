#
# halo.tcl --- Check that DRC errors are found regardless of where the
# DRC check area boundaries fall.  See README.md.
#
# A pair of poly contacts with a corner-to-corner spacing violation is
# placed in its own cell at x = 0, 2, 4, ... 1598.  How the cell is divided
# into DRC check areas depends on its position, so this covers many
# offsets of the error relative to a check area boundary.  Every pair
# must be flagged.

snap internal
set a 46
set b 3
set n 0
set missed 0

for {set x0 0} {$x0 < 1600} {incr x0 2} {
    load halo_$x0 -quiet
    box values $x0 0 [expr {$x0 + 46}] 46
    paint pc
    set x2 [expr {$x0 - $a - 46}]
    box values $x2 [expr {46 + $b}] [expr {$x2 + 46}] [expr {92 + $b}]
    paint pc
    select top cell
    drc check
    drc catchup
    set found 0
    foreach {why boxes} [drc listall why] {
	if {$why eq "PCPC"} {set found 1}
    }
    if {!$found} {
	incr missed
	puts "  missed error at x = $x0"
    }
    incr n
}
puts "RESULT pairs=$n missed=$missed"
quit -noprompt
