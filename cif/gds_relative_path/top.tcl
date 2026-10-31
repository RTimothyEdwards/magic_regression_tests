# Step 3 (in magic/):  place sub/blk in "top" (giving "use blk blk_0 sub")
# and save it.
drc off
crashbackups stop
cellname create top
load top
box values 0 0 0 0
getcell sub/blk
save top
puts "DONE"
quit -noprompt
