# Queue cell "a" for DRC twice, delete it, then run the pending checks.
load a
box 0 0 10 10
paint m1
box 20 0 30 10
paint m1
load b
cellname delete a -noprompt
drc catchup
puts "DONE"
quit -noprompt
