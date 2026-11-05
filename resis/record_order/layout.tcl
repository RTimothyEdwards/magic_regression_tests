# layout.tcl --- Make the cell for $env(CASE) and extract it.  "drivers" draws
# two equal nfets, each with its own gate, driving one output wire from opposite
# ends, so that neither is the larger driver.  "mux4" is the flattened standard
# cell sky130_fd_sc_hd__mux4_4, which has many devices in parallel and an output
# with several ports.

crashbackups stop
drc off

proc rect {x0 y0 x1 y1 type} {
    box values ${x0}um ${y0}um ${x1}um ${y1}um
    paint $type
}
proc pin {name x0 y0 x1 y1 type} {
    box values ${x0}um ${y0}um ${x1}um ${y1}um
    label $name c $type
    port make
}

if {$env(CASE) eq "drivers"} {
    cellname create drivers
    load drivers
    foreach {x g s} {0 g1 s1 40 g2 s2} {
	rect $x 0 [expr {$x + 2}] 2 ndiff
	rect [expr {$x + 0.8}] -1 [expr {$x + 1.2}] 2.5 poly
	pin $g [expr {$x + 0.8}] -1 [expr {$x + 1.2}] -0.6 poly
	rect $x 0.8 [expr {$x + 0.5}] 1.2 ndc
	rect [expr {$x + 1.5}] 0.8 [expr {$x + 2}] 1.2 ndc
	rect [expr {$x - 0.1}] 0.7 [expr {$x + 0.6}] 1.3 li
	pin $s [expr {$x - 0.1}] 0.7 [expr {$x + 0.6}] 1.3 li
	rect [expr {$x + 1.4}] 0.7 [expr {$x + 2.1}] 4 li
    }
    rect 1.4 3.5 42.1 4 li
    pin out 20 3.5 20.5 4 li
} else {
    gds readonly true
    gds read $env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
    load sky130_fd_sc_hd__mux4_4
    select top cell
    flatten mux4
    load mux4
}
save $env(CASE)
extract all
quit -noprompt
