drc $::env(DRC_STATE)
def read $::env(DEFFILE)
writeall force
puts "DONE"
quit -noprompt
