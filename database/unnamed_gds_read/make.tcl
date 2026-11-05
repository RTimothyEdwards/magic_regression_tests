drc off
load cella -silent
box 0 0 10 10
paint metal1
gds write cella.gds
puts "DONE"
quit -noprompt
