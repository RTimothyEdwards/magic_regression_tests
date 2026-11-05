# layout.tcl --- Draw one resistor with ports a and b:  $env(CASE) is "metal"
# (rmetal1, "device resistor") or "poly" (xhrpoly, "device rsubcircuit", which
# has "l=l+0.16" in the tech file).  Write the netlist with $env(TEE) and
# $env(HIER).

crashbackups stop
drc off
cellname create res
load res

proc rect {x0 y0 x1 y1 type} {
    box values ${x0}um ${y0}um ${x1}um ${y1}um
    paint $type
}
proc pin {name x0 y0 x1 y1 type} {
    box values ${x0}um ${y0}um ${x1}um ${y1}um
    label $name c $type
    port make
}

if {$env(CASE) eq "metal"} {
    rect 0 0 60 0.5 m1
    rect 25 0 35 0.5 rmetal1
    pin a 0 0 0.5 0.5 m1
    pin b 59.5 0 60 0.5 m1
} else {
    rect 0 0 2 0.35 xpc
    rect 2 0 58 0.35 xhrpoly
    rect 58 0 60 0.35 xpc
    rect 0 0 2 0.35 li
    rect 58 0 60 0.35 li
    pin a 0 0 2 0.35 li
    pin b 58 0 60 0.35 li
}
save res

extract all
ext2spice cthresh infinite
ext2spice resistor tee $env(TEE)
ext2spice hierarchy $env(HIER)
ext2spice subcircuit top on
ext2spice -o out.spice
quit -noprompt
