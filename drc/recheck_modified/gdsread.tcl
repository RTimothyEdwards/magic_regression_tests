# Cells read from GDS are recorded as needing to be checked only as requested
# by "gds drccheck", whether the DRC is on or off.  This is how a PDK gets views
# that are clean by design.
drc $::env(DRC_STATE)
gds readonly true
gds rescale false
gds drccheck $::env(GDS_DRCCHECK)
gds read ../gcell.gds
writeall force
puts "DONE"
quit -noprompt
