# Step 2:  in a new session, place the saved cell with "getcell" (which
# reads it from its file) and select the top cell.  The selected area must
# be the bounding box of the paint, not of the label text.  The box is
# written to bbox.txt.

drc off
crashbackups stop
cellname create top
load top
box values -50 144 -50 144
getcell cell_with_label
select top cell
set f [open bbox.txt w]
puts $f [box values]
close $f
save top
puts "DONE"
quit -noprompt
