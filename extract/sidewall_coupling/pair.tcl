# Draw two parallel 0.5um wide, 50um long wires on layer $env(SWLAYER)
# with separation $env(SWSEP) um, labeled a and b, and extract them.

crashbackups stop
drc off
set layer $env(SWLAYER)
set s $env(SWSEP)
set name pair_${layer}_[string map {. p} $s]
cellname create $name
load $name
box values 0 0 50um 0.5um
paint $layer
box values 0 0 0.5um 0.5um
label a c $layer
box values 0 [expr {0.5 + $s}]um 50um [expr {1.0 + $s}]um
paint $layer
box values 0 [expr {0.5 + $s}]um 0.5um [expr {1.0 + $s}]um
label b c $layer
extract all
quit -noprompt
