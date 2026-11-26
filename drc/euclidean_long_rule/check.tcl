# Check rule Padb.b (solder bump spacing 7000 internal units) between two
# solder pads placed corner to corner, with Euclidean distance on and off.
# The expected result is computed from the geometry:  with Euclidean
# distance, the corners are "gap * sqrt(2)" apart;  without it, the
# distance is the gap itself.  There is an error if that is less than the
# rule distance.  Each case prints a RESULT line.
#
# Environment:  TESTDIR (for s5500.mag).

crashbackups stop
snap internal
drc style drc(full)
# Solder is a locked type in the tech file;  unlock it to paint test cells.
tech unlock solder
set rule 7000
set size 6000

# Report one case:  "name" is the cell, "gap" the corner offset in x and
# y, and "euclid" whether Euclidean distance is used.

proc check_case {name gap euclid} {
    global rule
    if {$euclid} {
	drc euclidean on
	set dist [expr {$gap * sqrt(2.0)}]
    } else {
	drc euclidean off
	set dist $gap
    }
    load $name
    select top cell
    drc check
    drc catchup
    set found 0
    foreach {why boxes} [drc listall why] {
	if {[string match "*(Padb.b)*" $why]} {
	    set found [llength $boxes]
	}
    }
    set expect [expr {$dist < $rule}]
    set ok [expr {($found > 0) == $expect}]
    puts [format "RESULT %-12s gap=%d euclidean=%d distance=%.1f expect_error=%d errors=%d %s" \
	    $name $gap $euclid $dist $expect $found [expr {$ok ? "ok" : "WRONG"}]]
}

# Make a cell with two pads whose corners are offset by "gap".

proc make_case {name gap} {
    global size
    load $name -silent
    box values 0 0 $size $size
    paint solder
    set o [expr {$size + $gap}]
    box values $o $o [expr {$o + $size}] [expr {$o + $size}]
    paint solder
}

addpath $env(TESTDIR)

# The layout from github issue #600:  gap 5500, so 7778 apart.
check_case s5500 5500 1

# Without Euclidean distance, the same layout is an error.
check_case s5500 5500 0

# Just inside and just outside the rule (6930 and 7071 apart).
make_case g4900 4900
check_case g4900 4900 1
make_case g5000 5000
check_case g5000 5000 1

puts DONE
quit -noprompt
