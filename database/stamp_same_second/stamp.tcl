drc off
load parent -silent
select top cell
expand
load cell -silent
set last 0
for {set i 0} {$i < 10} {incr i} {
    box [expr {20 + $i * 20}] 0 [expr {30 + $i * 20}] 10
    paint metal1
    save
    set stamp [cellname timestamp cell]
    if {$stamp == $last} {puts "SAME_SECOND"}
    set last $stamp
    if {[lsearch [cellname flags cell] timestamp-pending] >= 0} {puts "PENDING"}
}

# Time for the clock to reach the next second
after 1100
box 400 0 410 10
paint metal1
save
if {[cellname timestamp cell] != $last} {puts "NEW_STAMP"}
if {[lsearch [cellname flags cell] timestamp-pending] >= 0} {puts "PENDING"}

load parent -silent
save
puts "DONE"
quit -noprompt
