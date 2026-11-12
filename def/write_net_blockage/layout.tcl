# Two metal1 wires:  one with a port label, written as a net, and one
# with no label, written as a blockage.
snap internal
cellname create top
load top
box values 0 0 400 40
paint metal1
box values 0 200 400 240
paint metal1
box values 0 200 20 240
label A c metal1
port make 1
extract all
def write top
puts "DEF DONE"
quit -noprompt
