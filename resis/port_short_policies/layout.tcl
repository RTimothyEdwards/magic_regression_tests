crashbackups stop
drc off
load wire
box values 0um 0um 2000um 0.5um
paint m1
box values 0um 10um 100um 12.5um
paint m2
set index 1
foreach {name layer x y} {A0 m1 0.25 0.25 AM m1 1000 0.25 A1 m1 1999.75 0.25 B0 m2 0.5 11.25 B1 m2 99.5 11.25} {
    box values ${x}um ${y}um ${x}um ${y}um
    label $name c $layer
    port make $index
    incr index
}
save wire
if {$env(MODE) ne "off"} {
    extract do resistance
    if {$env(MODE) ne "default"} {
        extresist threshold 0
        extresist mindelay 0
        extresist minres 0
        extresist prune 0
    }
}
extract all
if {$env(MODE) eq "missing"} {
    file delete wire.res.ext
}
ext2spice lvs
ext2spice cthresh 0
ext2spice rthresh 0
ext2spice short $env(SHORT_POLICY)
if {$env(MODE) eq "off"} {
    ext2spice extresist off
} else {
    ext2spice extresist on
}
ext2spice -o wire.spice
puts PORT_POLICIES_DONE
quit -noprompt
