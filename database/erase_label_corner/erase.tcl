# Erase a corner of a shape that has a label covering the whole shape.
# The label must stay attached to the shape.  Cases are chosen by the
# environment variable CASE:  the corner erased (ne, sw), or a strip along
# one side (edge).

drc off
crashbackups stop
cellname create a
load a
box values 0 0 20 20
paint m1
label A center m1
switch $env(CASE) {
    ne		{ box values 15 15 20 20 }
    sw		{ box values 0 0 5 5 }
    edge	{ box values 0 17 20 20 }
}
erase m1
save $env(CASE)
puts "DONE"
quit -noprompt
