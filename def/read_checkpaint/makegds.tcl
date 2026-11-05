drc off
load annotated -silent
box 0 0 100 100
paint metal1
gds write annotated.gds
puts "DONE"
quit -noprompt
