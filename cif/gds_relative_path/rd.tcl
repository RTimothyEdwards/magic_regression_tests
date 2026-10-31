# Step 2 (in magic/sub/):  read ../../gds/blk.gds as a read-only cell, so
# that its GDS_FILE property is the relative path "../../gds/blk.gds", and
# save it as blk.mag in this directory.
drc off
crashbackups stop
gds readonly true
gds read ../../gds/blk.gds
puts "GDS_FILE [cellname property blk GDS_FILE]"
save blk
puts "DONE"
quit -noprompt
