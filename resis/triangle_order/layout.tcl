# A vertical metal1 rail crossed by a horizontal metal2 strap.  All the
# via cuts are on the same row: the metal1 side becomes one internal
# node, connected to the two rail ends and to every cut.  On metal2 the
# cuts have different X coordinates, forming triangles with that node.
crashbackups stop
drc off

# Keep the allocation live through extraction.  Different lengths perturb
# addresses without changing the layout, labels or extraction options.
set heap_padding [string repeat x $env(HEAP_PAD_BYTES)]
cellname create top
load top

box values 0 0 220 600
paint metal1
box values -200 250 600 350
paint metal2
for {set i 0} {$i < $env(CONTACTS)} {incr i} {
    set x [expr {10 + 16 * $i}]
    box values $x 298 [expr {$x + 4}] 302
    paint m2contact
}
foreach {name x0 y0 x1 y1 layer} {
    A 100 0 104 4 metal1
    B 100 596 104 600 metal1
    C -200 298 -196 302 metal2
    D 596 298 600 302 metal2
} {
    box values $x0 $y0 $x1 $y1
    label $name c $layer
    port make
}
save top
extract all
extresist threshold 0
extresist mindelay 0
extresist minres 0
extresist all
puts DONE
quit -noprompt
