# R-C extract the sky130 inv_2 cell itself, whose labels are ports.
load sky130_fd_sc_hd__inv_2
extract path .
extresist mindelay 0
extract do resistance
extract all
puts "DONE"
quit -noprompt
