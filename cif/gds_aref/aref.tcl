# Read test.gds, flatten the top cell inside magic, and write the
# flattened cell as flat.gds.  Flattening matters:  an array read wrongly
# can still be written back out exactly as it was read (for example, with
# a bogus step in the unused direction), so only the geometry in magic's
# database shows the error.

drc off
crashbackups stop
gds read test.gds
load TOP
flatten TOP_flat
load TOP_flat
gds write flat.gds
puts "DONE"
quit -noprompt
