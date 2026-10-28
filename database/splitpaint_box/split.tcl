# "splitpaint" and "spliterase" with a zero-size box (GitHub issue #94) and
# on a locked layer (issue #95).  Each step saves the cell, and run.sh
# checks the saved layouts.

drc off
crashbackups stop
cellname create a
load a

# Zero-size box:  nothing should be painted or erased.
box values 10 10 10 10
splitpaint ne m1
save zero_paint
box values 0 0 20 20
paint m2
box values 10 10 10 10
spliterase sw m2
save zero_erase

# Locked layer:  "splitpaint" must not paint it and "spliterase" must not
# erase it.
tech lock m2
box values 40 0 60 20
splitpaint nw m2
save locked_paint
box values 0 0 20 20
spliterase ne m2
save locked_erase
tech unlock m2

puts "DONE"
quit -noprompt
