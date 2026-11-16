crashbackups stop
drc off
load long_names
set prefix [string repeat n $env(NAME_LENGTH)]
proc rect {x0 y0 x1 y1 layer} {
    box values [expr {$x0}]um [expr {$y0}]um [expr {$x1}]um [expr {$y1}]um
    paint $layer
}
proc pin {name x0 y0 x1 y1 layer} {
    box values [expr {$x0}]um [expr {$y0}]um [expr {$x1}]um [expr {$y1}]um
    label $name c $layer
    port make
}
if {$env(MODE) eq "wire"} {
    rect 0 0 200 1 m1
    rect 99.5 0 100.5 51 m1
    pin [format "%s_in" $prefix] 0 0 1 1 m1
    pin [format "%s_out" $prefix] 199 0 200 1 m1
    pin [format "%s_mid" $prefix] 99.5 50 100.5 51 m1
} else {
    foreach {y index} {0 1 0.7 2} {
        set c0 [expr {$y + 0.15}]
        set c1 [expr {$y + 0.45}]
        rect -0.5 $y 0.8 [expr {$y + 0.6}] ndiff
        rect 0 $y 0.15 [expr {$y + 0.6}] nfet
        rect -0.4 $c0 -0.1 $c1 ndc
        rect 0.3 $c0 0.6 $c1 ndc
        rect 0.3 $c0 50 $c1 li
        pin [format "s%s" $index] -0.4 $c0 -0.1 $c1 li
        pin [format "%s_d%s" $prefix $index] 49.7 $c0 50 $c1 li
    }
    rect 0 -0.2 0.15 1.5 poly
    pin g 0 -0.2 0.15 0 poly
}
save long_names
extresist threshold 0
extresist minres 0
extresist mindelay 0
extresist prune 0
extract do resistance
extract all
ext2spice cthresh 0
ext2spice extresist on
ext2spice -o extracted.spice
puts LONG_NAMES_DONE
quit -noprompt
