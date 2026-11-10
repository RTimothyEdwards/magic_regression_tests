# Two abutted sky130 inv_2 cells, flattened, then R-C extracted with
# "extresist mindelay 0" (and the default minres).
snap internal
load top
box 0 0 0 0
getcell sky130_fd_sc_hd__inv_2
set ab [instance list abutment]
set bb [box values]
set dx [expr {[lindex $ab 2] - [lindex $ab 0]}]
box [expr {[lindex $bb 0] + $dx}] [lindex $bb 1] [expr {[lindex $bb 0] + $dx}] [lindex $bb 1]
getcell sky130_fd_sc_hd__inv_2
select top cell
flatten top_flat
load top_flat
cellname delete top -noprompt
select top cell
extresist mindelay 0
extract do resistance
extract all
puts "DONE"
quit -noprompt
