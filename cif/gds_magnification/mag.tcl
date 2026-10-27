# Read test.gds and write it back out, normally (out.gds) or with
# "gds readonly true" (out_ro.gds), according to the environment
# variable MODE.  For the normal read, save every cell as a .mag file so
# that the cell use transforms can be checked.

drc off
crashbackups stop
if {$env(MODE) == "readonly"} {
    gds readonly true
}
gds read test.gds
puts "CELLS: [lsort [cellname list allcells]]"
foreach c [cellname list allcells] {
    if {[string first "_mag" $c] > 0} {
	puts "SOURCE $c: [cellname property $c GDS_MAG_SOURCE]"
    }
}
load TOP
if {$env(MODE) == "readonly"} {
    gds write out_ro.gds
} else {
    gds write out.gds
    writeall force
}
puts "DONE"
quit -noprompt
