# Step 1:  make a cell whose label text extends far outside its paint,
# and save it.

drc off
crashbackups stop
cellname create cell_with_label
load cell_with_label
box values 0 0 71 78
paint m1
label cell_with_a_long_label FreeSans 800 0 0 0 center m1
save cell_with_label
puts "DONE"
quit -noprompt
