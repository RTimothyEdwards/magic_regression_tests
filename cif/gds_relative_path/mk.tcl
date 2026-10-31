# Step 1 (in gds/):  write the cell "blk" to blk.gds.
drc off
crashbackups stop
cellname create blk
load blk
box values 0 0 10 10
paint m1
gds write blk
puts "DONE"
quit -noprompt
