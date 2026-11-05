drc off
load usercell -silent
gds readonly true
gds rescale false
gds read $::env(GDSFILE)
puts "USERFLAGS [cellname flags usercell]"
puts "DONE"
quit -noprompt
