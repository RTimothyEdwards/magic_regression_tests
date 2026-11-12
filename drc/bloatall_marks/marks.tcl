# The psc and nsc contacts abut, so on the metal1 plane the bloat-all
# search can spread from the psc seed into the nsc tile.  Both contacts
# carry a port label, which makes the extractor read those tiles.
tech load $env(TESTDIR)/tiny.tech
cellname create t1
load t1
box 0 0 40 40;    paint psd
box 10 10 20 20;  paint psc
box 20 10 30 20;  paint nsc
box -20 10 60 20; paint metal1
box 12 12 18 18;  label VSS center metal1
port make 1
box 22 12 28 18;  label VDD center metal1
port make 2
select top cell
drc style $env(DSTYLE)
drc check
drc catchup
puts "DRC [drc list count total]"
extract path [pwd]
extract all
puts "EXTRACT DONE"
quit -noprompt
