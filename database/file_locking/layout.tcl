# Make a top cell "top" with three subcells c0, c1 and c2.
crashbackups stop
foreach c {c0 c1 c2} {
    load $c
    box 0 0 10 10
    paint m1
    save $c
}
load top
set x 0
foreach c {c0 c1 c2} {
    box $x 0 $x 0
    getcell $c
    incr x 20
}
save top
puts LAYOUT_DONE
quit -noprompt
