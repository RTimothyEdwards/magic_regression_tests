# layout.tcl --- Draw two neighboring wires $env(CASE), extract with extresist
# options $env(RESOPTS), and write the netlist with and without the network.
#   ports:  m1 wires with a port at each end, so the original nets keep their
#           names and are not killed.
#   fets:   unlabeled li drain wires of two transistors, so the original nets
#           are replaced ("killnode") by the resistor network's nodes.

crashbackups stop
drc off
cellname create pair
load pair

proc rect {x0 y0 x1 y1 type} {
    box values ${x0}um ${y0}um ${x1}um ${y1}um
    paint $type
}
proc pin {name x0 y0 x1 y1 type} {
    box values ${x0}um ${y0}um ${x1}um ${y1}um
    label $name c $type
    port make
}

if {$env(CASE) eq "ports"} {
    foreach {y a b} {0 a1 a2 0.7 b1 b2} {
	set y1 [expr {$y + 0.5}]
	rect 0 $y 50 $y1 m1
	pin $a 0 $y 0.5 $y1 m1
	pin $b 49.5 $y 50 $y1 m1
    }
} else {
    foreach {y s} {0 s1 0.7 s2} {
	set c0 [expr {$y + 0.15}]
	set c1 [expr {$y + 0.45}]
	rect -0.5 $y 0.8 [expr {$y + 0.6}] ndiff
	rect 0 $y 0.15 [expr {$y + 0.6}] nfet
	rect -0.4 $c0 -0.1 $c1 ndc
	rect 0.3 $c0 0.6 $c1 ndc
	rect 0.3 $c0 50 $c1 li
	pin $s -0.4 $c0 -0.1 $c1 li
    }
    rect 0 -0.2 0.15 1.5 poly
    pin g 0 -0.2 0.15 0 poly
}
save pair

foreach opt $env(RESOPTS) {
    extresist {*}$opt
}
extract do resistance
extract all
ext2spice cthresh 0
ext2spice extresist off
ext2spice -o $env(CASE)_lumped.spice
ext2spice extresist on
ext2spice -o $env(CASE).spice
quit -noprompt
