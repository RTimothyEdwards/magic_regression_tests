# Step 1:  write the cell "blk" to blk.gds.

drc off
crashbackups stop
cellname create blk
load blk
box values 0 0 79 309
paint m1
box values 0 0 244 56
paint m1
gds write blk
puts "DONE"
quit -noprompt
