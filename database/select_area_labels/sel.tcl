# Select with "select area" (in the form given by the environment
# variable SEL) and move the selection north by 100, so that the saved
# layout shows what was selected.  The layout:  a metal1 square with a
# label on it ("onmetal"), a label on space ("onspace"), and an instance
# of cell "sub", all inside the box.

drc off
crashbackups stop
cellname create sub
load sub
box values 0 0 10 10
paint m2
save sub

cellname create top
load top
box values 0 0 10 10
paint m1
label onmetal center m1
box values 30 0 30 0
label onspace
box values 50 0 50 0
getcell sub
box values -5 -5 70 15
eval $env(SEL)
move n 100
save top
puts "DONE"
quit -noprompt
