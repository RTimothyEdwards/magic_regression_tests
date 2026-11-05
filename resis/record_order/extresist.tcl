# extresist.tcl --- Run extresist on the cell $env(CASE), reading the .ext file
# in the current directory.

crashbackups stop
drc off
load $env(CASE)
select top cell
extresist threshold 0
extresist mindelay 0
extresist minres 0
extresist
quit -noprompt
