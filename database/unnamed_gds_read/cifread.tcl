drc off
cif read $::env(CIFFILE)
puts "FLAGS [cellname flags (UNNAMED)]"
select top cell
box
puts "PAINT [lindex [box values] 2]"
puts "DONE"
quit -noprompt
