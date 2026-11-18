# Read the layout with file locking enabled and keep the locks until the
# file "release" appears.  Cell c0 is changed and saved first, so its lock
# must be taken again after the file is rewritten.
crashbackups stop
load top
select top cell
expand
load c0
box 0 20 10 30
paint m2
save c0
load top
set f [open ready w]
puts $f [pid]
close $f
for {set i 0} {$i < 600 && ![file exists release]} {incr i} {
    after 100
}
puts HOLDER_DONE
quit -noprompt
