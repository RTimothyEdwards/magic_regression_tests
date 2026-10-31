# Step 4 (in magic/):  load "top" and write GDS.  The GDS for "blk" must be
# copied from ../../gds/blk.gds relative to magic/sub/, where blk.mag is.
drc off
crashbackups stop
load top
gds write out
puts "DONE"
quit -noprompt
