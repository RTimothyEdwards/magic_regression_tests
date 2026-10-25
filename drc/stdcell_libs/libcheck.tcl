#
# libcheck.tcl --- Run DRC on every cell of a standard cell library and
# print the DRC errors found in each cell, one line per error reason:
#
#	<cell> <error count> <reason>
#
# Environment variable LIBDIR is the library's "mag" directory.

set dir $env(LIBDIR)
foreach f [lsort [glob $dir/*.mag]] {
    load $f -dereference
    select top cell
    drc check
    drc catchup
    foreach {why boxes} [drc listall why] {
	puts "ERR [file rootname [file tail $f]] [llength $boxes] $why"
    }
}
quit -noprompt
