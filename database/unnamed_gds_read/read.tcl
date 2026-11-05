drc off
gds readonly true
gds drccheck false
gds rescale false
gds read $::env(GDSFILE)
puts "FLAGS [cellname flags (UNNAMED)]"
puts "TOP [cellname list top]"
writeall force
puts "DONE"
quit -noprompt
