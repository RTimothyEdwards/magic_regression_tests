# following_device.tcl --- Draw resistors and FETs side by side, so that a FET
# follows a resistor in the list of devices.  Write the netlist with $env(TEE)
# and $env(HIER).

crashbackups stop
drc off
cellname create mixed
load mixed

proc rect {x0 y0 x1 y1 type} {
    box values ${x0}um ${y0}um ${x1}um ${y1}um
    paint $type
}

foreach x {0 20 40} {
    rect $x 0 [expr {$x + 10}] 0.5 m1
    rect [expr {$x + 4}] 0 [expr {$x + 6}] 0.5 rmetal1
}
foreach x {10 30} {
    rect $x 5 [expr {$x + 2}] 7 ndiff
    rect [expr {$x + 0.8}] 4.5 [expr {$x + 1.2}] 7.5 poly
}
save mixed

extract all
ext2spice cthresh infinite
ext2spice resistor tee $env(TEE)
ext2spice hierarchy $env(HIER)
ext2spice subcircuit top on
ext2spice -o out.spice
quit -noprompt
