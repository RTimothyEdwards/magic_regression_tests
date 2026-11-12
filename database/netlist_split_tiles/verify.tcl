# The same wire, with terminal A on the rectangle and terminal B on the
# triangle.  "verify" must find A and B connected.
cellname create ver
load ver
box 30 0 50 10
paint metal1
box 20 0 30 10
splitpaint se metal1
box 40 4 40 4
label A c metal1
box 28 1 28 1
label B c metal1
save ver
specialopen netlist
netlist ver
verify
puts "VERIFY DONE"
quit -noprompt
