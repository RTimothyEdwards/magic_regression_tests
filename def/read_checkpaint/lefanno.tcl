drc off
gds readonly true
gds drccheck no
gds rescale false
gds read $::env(GDSFILE)
lef read $::env(LEFFILE)
writeall force
puts "DONE"
quit -noprompt
