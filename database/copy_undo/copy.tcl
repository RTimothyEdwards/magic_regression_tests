# Copy a cell instance four times with "copy", then "undo" three times.
# One copy should remain (two instances in all).  The instance names are
# written to instances.txt after the copies and after the undos.

drc off
crashbackups stop
cellname create sub
load sub
box values 0 0 10 10
paint m1
save sub

cellname create top
load top
box values 0 0 0 0
getcell sub
copy e 20
copy e 20
copy e 20
copy e 20
set f [open instances.txt w]
puts $f "copied [llength [cellname list childinst top]]"
undo
undo
undo
puts $f "undone [llength [cellname list childinst top]]"
close $f
save top
puts "DONE"
quit -noprompt
