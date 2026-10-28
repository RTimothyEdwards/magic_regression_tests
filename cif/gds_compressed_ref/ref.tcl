# Step 2:  read blk.gds as a read-only (vendor GDS) cell, so that "blk"
# gets the properties GDS_FILE, GDS_START, and GDS_END;  place it in "top"
# and save both cells.

drc off
crashbackups stop
gds readonly true
gds read blk.gds
puts "GDS_FILE [cellname property blk GDS_FILE]"
cellname create top
load top
box values 0 0 0 0
getcell blk
writeall force
puts "DONE"
quit -noprompt
