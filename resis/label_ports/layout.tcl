# One sky130 inv_2 cell, flattened, then R-C extracted with
# "extresist mindelay 0".
snap internal
load top
box 0 0 0 0
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
