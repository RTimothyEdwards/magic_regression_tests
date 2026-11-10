# R-C extract a flattened copy of the sky130 inv_2 cell.  Flattening
# removes the port flags, so its labels are no longer ports.
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
