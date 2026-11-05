# layout.tcl --- Draw two neighboring wires, each with a resistor in the middle,
# with a port at each end.  $env(CASE) is "metal" (rmetal1 in m1, "device
# resistor" in the tech file) or "poly" (xhrpoly in xpc-contacted poly,
# "device rsubcircuit").  Extract coupling capacitance, and write the netlist
# with $env(TEE) and $env(HIER).

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

foreach {y a b} {0 a1 a2 1.0 b1 b2} {
    set y1 [expr {$y + 0.5}]
    if {$env(CASE) eq "metal"} {
	rect 0 $y 60 $y1 m1
	rect 25 $y 35 $y1 rmetal1
	pin $a 0 $y 0.5 $y1 m1
	pin $b 59.5 $y 60 $y1 m1
    } else {
	set y1 [expr {$y + 0.35}]
	rect 0 $y 2 $y1 xpc
	rect 2 $y 58 $y1 xhrpoly
	rect 58 $y 60 $y1 xpc
	rect 0 $y 2 $y1 li
	rect 58 $y 60 $y1 li
	pin $a 0 $y 2 $y1 li
	pin $b 58 $y 60 $y1 li
    }
}
save pair

extract do coupling
extract all

# The tech file gives xhrpoly no coupling capacitance, so add a record for
# coupling between the two resistor bodies to the .ext file.
if {$env(CASE) eq "poly"} {
    set f [open pair.ext a]
    puts $f "cap \"a_400_0#\" \"a_400_200#\" 100"
    close $f
}
ext2spice cthresh 0
ext2spice resistor tee $env(TEE)
ext2spice hierarchy $env(HIER)
ext2spice subcircuit top on
ext2spice -o out.spice
quit -noprompt
