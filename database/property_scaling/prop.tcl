# FIXED_BBOX and mask hint properties must follow the geometry when the
# grid is rescaled ("scalegrid") and when the cell origin is moved ("move
# origin").  Values are written to props.txt, one line per step:
#   <step> <paint bbox> | <FIXED_BBOX> | <MASKHINTS_m2>

drc off
crashbackups stop
cellname create a
load a
box values 0 0 10 10
paint m1
property FIXED_BBOX "0 0 1000 1000"
property MASKHINTS_m2 "0 0 100 100 200 200 300 300"

set f [open props.txt w]
proc report {f step} {
    select top cell
    puts $f "$step [box values] | [property FIXED_BBOX] | [property MASKHINTS_m2]"
    flush $f
    select clear
}
report $f start
scalegrid 1 2
report $f scaled
box values 0 0 0 0
move origin e 10
report $f moved
close $f
puts "DONE"
quit -noprompt
