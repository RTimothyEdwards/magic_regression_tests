# layout.tcl --- Place sky130 standard cells, one of them arrayed, under metal
# wires, extract with coupling capacitance, and write flat and hierarchical
# netlists.

crashbackups stop
drc off
gds readonly true
gds read $env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
cellname create top
load top

set x 0
foreach c {sky130_fd_sc_hd__mux4_4 sky130_fd_sc_hd__buf_16 sky130_fd_sc_hd__dfxtp_4} {
    box values ${x}um 0 ${x}um 0
    getcell $c
    set x [expr {$x + 12}]
}
box values ${x}um 0 ${x}um 0
getcell sky130_fd_sc_hd__clkinv_16
array 1 3 0 0

foreach y {0.5 1.2 2.0 3.0 4.1} {
    box values 0 ${y}um 50um [expr {$y + 0.14}]um
    paint m2
}
box values 1um 0 1.2um 8um
paint m3

extract do coupling
extract all
ext2spice cthresh 0
ext2spice hierarchy on
ext2spice -o hier.spice
ext2spice hierarchy off
ext2spice -o flat.spice
quit -noprompt
