# The same steps that open-pdks uses to make a GDS library
drc off
gds readonly true
gds rescale false
gds read $::env(GDSFILE)
cellname delete \(UNNAMED\)
set glist [cellname list top]
puts "GLIST $glist"
load mylib
box values 0 0 0 0
foreach gcell $glist {
    getcell $gcell
    box move e 200
}
gds library true
gds write mylib
puts "DONE"
quit -noprompt
