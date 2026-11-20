# Two aligned square plates on metal1 and metal2.
crashbackups stop
drc off
load plate
set side $env(SIDE_UM)
box values 0um 0um ${side}um ${side}um
paint m1
paint m2
box values 1um 1um 1um 1um
label a c m1
port make 1
box values 2um 2um 2um 2um
label b c m2
port make 2
save plate
extract no resistance
extract do capacitance
extract do coupling
extract style ngspice()
extract all
ext2spice lvs
ext2spice cthresh 0
ext2spice extresist off
ext2spice -o plate.spice
puts LARGE_OVERLAP_DONE
quit -noprompt
