# A metal1 wire whose left end is a triangle on the right side of a split
# tile (the left side is space).  "ripup" from the wire must remove both.
cellname create rip
load rip
box 30 0 50 10
paint metal1
box 20 0 30 10
splitpaint se metal1
box 40 2 42 4
specialopen netlist
ripup
closewindow [lindex [windownames] end]
save rip
puts "RIPUP DONE"
quit -noprompt
