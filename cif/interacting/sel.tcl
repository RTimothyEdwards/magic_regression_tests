# Three metal1 squares far from the origin (so that magic and CIF units
# are different areas):  A overlaps poly, B abuts poly, C has no poly;
# and the same three at negative coordinates.
tech load $env(TESTDIR)/tiny.tech
cif ostyle sel
cellname create t1
load t1
box 1000 1000 1010 1010; paint metal1
box 1005 1005 1015 1015; paint poly
box 1100 1000 1110 1010; paint metal1
box 1110 1000 1120 1010; paint poly
box 1200 1000 1210 1010; paint metal1
# The same at negative coordinates (mirrored in x)
box -1010 -1010 -1000 -1000; paint metal1
box -1015 -1015 -1005 -1005; paint poly
box -1110 -1010 -1100 -1000; paint metal1
box -1120 -1010 -1110 -1000; paint poly
box -1210 -1010 -1200 -1000; paint metal1
select top cell
foreach l {ALL OV NOV INT NINT OVc NOVc INTc NINTc} {
    puts "LAYER $l"
    cif coverage $l
}
quit -noprompt
