# resis_wire.tcl --- Draw a straight wire on layer $env(WIRELAYER),
# $env(WIRELEN) um long and $env(WIREWID) um wide, with ports IN and OUT
# at the two ends (each a square label the width of the wire), then
# extract it with extresist and write SPICE with "ext2spice lvs".
# Extresist options are taken from $env(RESOPTS) (a Tcl list of
# {option value} pairs).  The cell (and SPICE file) is named
# $env(WIRENAME) if set, or else wire_<layer>.  If $env(WIREMID) is 1, a
# third port MID is added in the middle of the wire.  If $env(WIRECAPS) is
# 1, capacitors are kept, and <name>_lumped.spice is also written without
# the extresist network.

crashbackups stop
drc off
set layer $env(WIRELAYER)
set len $env(WIRELEN)
set wid $env(WIREWID)
if {[info exists env(WIRENAME)]} {
    set name $env(WIRENAME)
} else {
    set name wire_$layer
}

cellname create $name
load $name
box values 0 0 ${len}um ${wid}um
paint $layer
box values 0 0 ${wid}um ${wid}um
label IN c $layer
port make 1
box values [expr {$len - $wid}]um 0 ${len}um ${wid}um
label OUT c $layer
port make 2
# Optional third port in the middle of the wire
if {[info exists env(WIREMID)] && $env(WIREMID)} {
    set x0 [expr {($len - $wid) / 2.0}]
    box values ${x0}um 0 [expr {$x0 + $wid}]um ${wid}um
    label MID c $layer
    port make 3
}
save $name

foreach opt $env(RESOPTS) {
    extresist {*}$opt
}
extract do resistance
extract all
if {[info exists env(WIRECAPS)] && $env(WIRECAPS)} {
    # Keep capacitors in the output, and write the netlist with and
    # without the extresist network.
    ext2spice cthresh 0
    ext2spice extresist off
    ext2spice -o ${name}_lumped.spice
    ext2spice extresist on
    ext2spice -o $name.spice
} else {
    ext2spice lvs
    ext2spice extresist on
    ext2spice -o $name.spice
}
quit -noprompt
