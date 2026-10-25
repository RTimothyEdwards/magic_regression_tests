#
# sweep.tcl --- Sweep test of Euclidean DRC corner checks on derived
# (contact) types, using gf180mcuD.
#
# In gf180mcuD, every contact type is drawn 5nm larger than its cut on
# each side, and DRC rules that apply to contact cuts are written against
# the contact type with the distance reduced by that border (once for each
# side of the rule that is a cut).  That is exact for straight edges, but
# not for corner-to-corner (Euclidean) distances unless magic measures the
# corner distance from the corner of the cut and not the corner of the
# contact type.
#
# Each case places geometry at many offsets (A, B) around a corner and
# compares magic's DRC result against the true result computed from the
# cut geometry:
#
#	error = max(0, A + bt)^2 + (B + bt)^2 < (d + bt)^2
#
# where d is the rule distance in the tech file and bt is the total border
# of the sides that are cuts.  All values are in 5nm units, multiplied by
# SWEEPSCALE (1 for a 5nm internal grid, 5 for a 1nm internal grid).
#
# Environment variables:
#   SWEEPCASE	name placer type1 type2 dir d bt whypattern
#   SWEEPSCALE	internal grid units per 5nm (default 1)
#
# Placers:
#   place_spacing   type1 at the origin, type2 offset by (A, B) beyond its
#		    NE or NW corner.
#   place_notch	    type1 (inner) surrounded by type2, with a notch in type2
#		    at (A, B) beyond the NE, NW, SW, or SE corner of type1.
#
# Output:  One line "RESULT <name> sites=n correct=n false_pos=n false_neg=n"
# preceded by one line for each incorrect site.

set k 1
if {[info exists env(SWEEPSCALE)]} {set k $env(SWEEPSCALE)}

snap internal
set pitch [expr {600 * $k}]
set ncols 40

# Object sizes (5nm units)
array set size {pc {46 46} ndc {46 46} pdc {46 46} rpp {100 100} ndif {100 100}}

proc rect {type x1 y1 x2 y2} {
    box values $x1 $y1 $x2 $y2
    paint $type
}

proc place_spacing {t1 t2 dir x0 y0 a b} {
    global size k
    lassign $size($t1) w1 h1
    lassign $size($t2) w2 h2
    set w1 [expr {$w1 * $k}]; set h1 [expr {$h1 * $k}]
    set w2 [expr {$w2 * $k}]; set h2 [expr {$h2 * $k}]
    rect $t1 $x0 $y0 [expr {$x0 + $w1}] [expr {$y0 + $h1}]
    set y2 [expr {$y0 + $h1 + $b}]
    switch $dir {
	NE {set x2 [expr {$x0 + $w1 + $a}]}
	NW {set x2 [expr {$x0 - $a - $w2}]}
    }
    rect $t2 $x2 $y2 [expr {$x2 + $w2}] [expr {$y2 + $h2}]
}

proc place_notch {t1 t2 dir x0 y0 a b} {
    global size k
    lassign $size($t1) w1 h1
    set w1 [expr {$w1 * $k}]; set h1 [expr {$h1 * $k}]
    set m [expr {200 * $k}]
    set xl [expr {$x0 - $m}]; set xr [expr {$x0 + $w1 + $m}]
    set yb [expr {$y0 - $m}]; set yt [expr {$y0 + $h1 + $m}]
    rect $t2 $xl $yb $xr $yt
    switch $dir {
	NE {box values [expr {$x0 + $w1 + $a}] [expr {$y0 + $h1 + $b}] $xr $yt}
	NW {box values $xl [expr {$y0 + $h1 + $b}] [expr {$x0 - $a}] $yt}
	SW {box values $xl $yb [expr {$x0 - $a}] [expr {$y0 - $b}]}
	SE {box values [expr {$x0 + $w1 + $a}] $yb $xr [expr {$y0 - $b}]}
    }
    erase $t2
    rect $t1 $x0 $y0 [expr {$x0 + $w1}] [expr {$y0 + $h1}]
}

proc truth {a b d bt} {
    set dx [expr {max(0, $a + $bt)}]
    set dy [expr {$b + $bt}]
    set r [expr {$d + $bt}]
    return [expr {$dx * $dx + $dy * $dy < $r * $r}]
}

proc runcase {name placer t1 t2 dir d bt whypat} {
    global pitch ncols k
    set d [expr {$d * $k}]
    set bt [expr {$bt * $k}]
    set r [expr {$d + $bt}]
    set band [expr {3 * $k}]

    # Sites in a band around the true error boundary, including the
    # straight-edge cases (A < 0).
    set sites {}
    for {set a [expr {-$band}]} {$a <= $r + $band} {incr a} {
	for {set b 0} {$b <= $r + $band} {incr b} {
	    set dx [expr {max(0, $a + $bt)}]
	    set dist [expr {sqrt($dx * $dx + ($b + $bt) * ($b + $bt))}]
	    if {abs($dist - $r) <= $band} {lappend sites [list $a $b]}
	}
    }

    load $name -quiet
    set i 0
    foreach s $sites {
	lassign $s a b
	set x0 [expr {($i % $ncols) * $pitch}]
	set y0 [expr {($i / $ncols) * $pitch}]
	$placer $t1 $t2 $dir $x0 $y0 $a $b
	incr i
    }
    select top cell
    drc check
    drc catchup

    array set flagged {}
    foreach {why boxes} [drc listall why] {
	if {![string match $whypat $why]} continue
	foreach bx $boxes {
	    lassign $bx x1 y1 x2 y2
	    set col [expr {int(floor(($x1 + $x2) / 2.0 / $pitch + 0.5))}]
	    set row [expr {int(floor(($y1 + $y2) / 2.0 / $pitch + 0.5))}]
	    set flagged([expr {$row * $ncols + $col}]) 1
	}
    }

    set ok 0; set fp 0; set fn 0
    set i 0
    foreach s $sites {
	lassign $s a b
	set want [truth $a $b $d $bt]
	set got [info exists flagged($i)]
	if {$want == $got} {
	    incr ok
	} elseif {$got} {
	    incr fp
	    puts "  $name: false positive at A=$a B=$b"
	} else {
	    incr fn
	    puts "  $name: false negative at A=$a B=$b"
	}
	incr i
    }
    puts [format "RESULT %-16s sites=%5d correct=%5d false_pos=%3d false_neg=%3d" \
		$name [llength $sites] $ok $fp $fn]
}

runcase {*}$env(SWEEPCASE)
quit -noprompt
