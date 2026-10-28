# Step 3:  after blk.gds has been compressed to blk.gds.gz, load "top" and
# write it as GDS.  The GDS of "blk" must be copied from blk.gds.gz.

drc off
crashbackups stop
load top
gds write out.gds
puts "DONE"
quit -noprompt
