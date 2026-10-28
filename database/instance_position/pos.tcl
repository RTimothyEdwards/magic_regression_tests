# Place instances of a cell (whose layout does not start at its origin) in
# several orientations, and an array, and report their positions with
# "instance position":  by name, for one selected instance, and for all
# selected instances.  Results go to pos.txt;  the cell is saved so that
# run.sh can compare with the transforms in the .mag file.

drc off
crashbackups stop
cellname create sub
load sub
box values 5 5 20 15
paint m1
save sub

cellname create top
load top
set n 0
foreach {x y orient} {0 0 0  100 50 90  200 0 h  300 40 180  400 0 270v} {
    box values $x $y $x $y
    getcell sub $orient
}
box values 0 200 0 200
getcell sub
box values 0 200 100 230
array 3 2
save top

set f [open pos.txt w]
foreach i {0 1 2 3 4 5} {
    puts $f "name sub_$i [instance position sub_$i]"
}
select cell sub_1
puts $f "selected1 [instance position]"
# Array elements, by name and by selecting one element ("array 3 2"
# above:  columns 100 apart, rows 30 apart)
foreach e {{sub_5[0][0]} {sub_5[0][2]} {sub_5[1][1]}} {
    puts $f "element $e [instance position $e]"
}
select clear
select cell {sub_5[1][2]}
puts $f "selectedelement [instance position]"
select top cell
select area subcell
puts $f "selectedall [lsort [instance position]]"
select clear
# Units:  after "scalegrid 1 2", internal units are half of lambda
scalegrid 1 2
units lambda
puts $f "lambda [instance position sub_1]"
units internal
puts $f "internal [instance position sub_1]"
close $f
puts "DONE"
quit -noprompt
