# Save a clean cell having the geometry, then annotate it in a second load.
drc on
def read $::env(DEFFILE)
select top cell
drc check
drc catchup
writeall force
cellname flush testdesign
drc off
load testdesign -silent
def read $::env(DEFFILE) -annotate
writeall force
puts "DONE"
quit -noprompt
