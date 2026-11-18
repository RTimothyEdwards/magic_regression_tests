crashbackups stop
drc off
load pair
proc rect {x0 y0 x1 y1 type} {
    box values ${x0}um ${y0}um ${x1}um ${y1}um
    paint $type
}
proc pin {name x0 y0 x1 y1 type} {
    box values ${x0}um ${y0}um ${x1}um ${y1}um
    label $name c $type
    port make
}
if {$env(FIXTURE_MODE) eq "ports"} {
    foreach {y left right} {0 a1 a2 0.7 b1 b2} {
        set y1 [expr {$y + 0.5}]
        rect 0 $y 50 $y1 m1
        pin $left 0 $y 0.5 $y1 m1
        pin $right 49.5 $y 50 $y1 m1
    }
} else {
    # No drain ports: extresist must replace the original drain nodes and
    # reattach coupling capacitors to the new resistance-network nodes.
    foreach {y source} {0 s1 0.7 s2} {
        set c0 [expr {$y + 0.15}]
        set c1 [expr {$y + 0.45}]
        rect -0.5 $y 0.8 [expr {$y + 0.6}] ndiff
        rect 0 $y 0.15 [expr {$y + 0.6}] nfet
        rect -0.4 $c0 -0.1 $c1 ndc
        rect 0.3 $c0 0.6 $c1 ndc
        rect 0.3 $c0 50 $c1 li
        pin $source -0.4 $c0 -0.1 $c1 li
    }
    rect 0 -0.2 0.15 1.5 poly
    pin g 0 -0.2 0.15 0 poly
}
save pair
extract no resistance
extract do capacitance
extract do coupling
extract all
puts INPUT_SCALES_DONE
quit -noprompt
