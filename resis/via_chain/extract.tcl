# Read vias.gds and extract each via chain cell with extresist, with all
# cutoffs at zero, writing <cell>.spice.

crashbackups stop
drc off
gds read vias.gds
extresist threshold 0
extresist mindelay 0
extresist minres 0
extract do resistance
ext2spice lvs
ext2spice extresist on
foreach cell [cellname list allcells] {
    if {![string match vc_* $cell]} continue
    load $cell
    extract all
    ext2spice -o $cell.spice
}
quit -noprompt
