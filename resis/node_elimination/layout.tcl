# A metal1 rail with eight ports, under a metal2 strap with one port, joined
# by three via arrays drawn as individual cuts.  Set ::N (array size) and
# ::PRUNE (extresist prune value, or "" for the default) before sourcing.
snap internal
load top
set n $::N
set pitch 100
set size 52
set span [expr {$n * $pitch}]
set len 40000
box 0 0 $len $span
paint m1
paint m2
foreach x0 {4000 20000 36000} {
    for {set i 0} {$i < $n} {incr i} {
	for {set j 0} {$j < $n} {incr j} {
	    set x [expr {$x0 + $i * $pitch + 24}]
	    set y [expr {$j * $pitch + 24}]
	    box $x $y [expr {$x + $size}] [expr {$y + $size}]
	    paint via1
	}
    }
}
for {set k 0} {$k < 8} {incr k} {
    set x [expr {1000 + $k * 5000}]
    box $x 0 [expr {$x + 50}] 50
    label P$k n m1
    port make
}
box [expr {$len - 50}] 0 $len 50
label S n m2
port make
extract path .
puts "PRUNE_DEFAULT=[extresist prune]"
if {[catch {extresist prune 1.5}]} {}
puts "PRUNE_AFTER_BAD=[extresist prune]"
if {$::PRUNE ne ""} {extresist prune $::PRUNE}
extresist all
extresist threshold 0
extresist mindelay 0
extresist minres 0
extract do resistance
extract all
puts "DONE"
quit -noprompt
