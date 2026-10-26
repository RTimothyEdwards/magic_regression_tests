#
# maxrect.tcl --- Build a ring of metal1 out of four subcells (two sides
# and two "corner" cells containing the top and bottom edges), placed far
# enough apart that the subcells interact only near the corners.  Write
# GDS hierarchically and flattened.  See README.md.

snap internal

load side
box 0 0 100 20000
paint m1
save side

load topbot
box 0 0 20000 100
paint m1
save topbot

load ring
box 0 0 0 0
getcell side
box 19900 0 19900 0
getcell side
box 0 -100 0 -100
getcell topbot
box 0 20000 0 20000
getcell topbot
save ring
gds write ring_hier

flatten ring_flat
load ring_flat
gds write ring_flat

puts "DONE"
quit -noprompt
