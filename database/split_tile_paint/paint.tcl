# Paint a box over existing split (non-Manhattan) tiles.  The case is
# chosen by the environment variable CASE.  The layout is saved before the
# paint (CASE_before.mag), after it (CASE_after.mag), and after "undo"
# (CASE_undo.mag).  The painted box is written to CASE_box.txt.

drc off
crashbackups stop
set case $env(CASE)
cellname create $case
load $case

switch $case {
    corner {
	# A box painted inside the corner of a triangle, where the top
	# right of the triangle was not clipped and a stripe of metal1
	# ran off to infinity;  "undo" then crashed.
	box values 0 0 20 20
	splitpaint sw m1
	set layer m1
	set paintbox {8 8 16 16}
    }
    stripe {
	# Two triangles on either side of a rectangle, and a box painted
	# across all three, overlapping them only partly.  The right side
	# of the area was not painted.
	box values 0 0 20 20
	splitpaint ne m2
	box values 20 0 40 60
	paint m2
	box values 40 0 60 20
	splitpaint nw m2
	set layer m2
	set paintbox {-6 15 65 60}
    }
    stripe_low {
	# The same, but with the box covering the triangles entirely
	# on the bottom.
	box values 0 0 20 20
	splitpaint ne m2
	box values 20 0 40 60
	paint m2
	box values 40 0 60 20
	splitpaint nw m2
	set layer m2
	set paintbox {-6 -5 65 10}
    }
    diagonal {
	# A box crossing the diagonal of a large triangle, overlapping
	# both of its sides.
	box values 0 0 40 40
	splitpaint nw m1
	set layer m1
	set paintbox {10 5 30 35}
    }
}

save ${case}_before
set f [open ${case}_box.txt w]
puts $f "[lindex [split [tech layers $layer] " "] 0] $paintbox"
close $f

box values {*}$paintbox
paint $layer
save ${case}_after
undo
save ${case}_undo
puts "DONE"
quit -noprompt
