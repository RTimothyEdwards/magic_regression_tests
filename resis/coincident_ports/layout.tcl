crashbackups stop
drc off
load wire
box values 0um 0um 1000um 0.5um
paint m1
# Port A at the left end; ports A and B on the same point at the right end.
# ORDER selects which of the two coincident labels is made first.
set labels [list {A 0.25} {A 999.75} {B 999.75}]
if {$env(ORDER) eq "ba"} {
    set labels [list {A 0.25} {B 999.75} {A 999.75}]
}
foreach item $labels {
    lassign $item name x
    box values ${x}um 0.25um ${x}um 0.25um
    label $name c m1
    port make [expr {($name eq "A") ? 1 : 2}]
}
save wire
if {$env(MODE) ne "off"} {
    extract do resistance
    if {$env(MODE) eq "strict"} {
        extresist threshold 0
        extresist mindelay 0
        extresist minres 0
        extresist prune 0
        extresist simplify on
    }
}
extract no unique
extract all
ext2spice lvs
ext2spice cthresh 0
ext2spice rthresh 0
ext2spice subcircuit top on
ext2spice short $env(SHORT_POLICY)
if {$env(MODE) eq "off"} {
    ext2spice extresist off
} else {
    ext2spice extresist on
}
ext2spice -o wire.spice
puts COINCIDENT_PORTS_DONE
quit -noprompt
