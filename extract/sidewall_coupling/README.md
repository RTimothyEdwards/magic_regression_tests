# Sidewall coupling between two parallel wires

Two parallel wires, 0.5um wide and 50um long, on metal1, metal3, and
metal5 of sky130A, at separations of 0.2 to 3.2um, extracted with
`extract all`.  The coupling capacitance in the .ext file must equal
the `defaultsidewall` coefficient of the layer (read from the nominal
extract style of the tech file) times the length, divided by the
separation plus the offset, within 1%.

The sidewall coefficient in a tech file is the coupling between two
edges.  Magic accumulates the coupling once from each of the two
facing edges, so each edge must contribute half.  Before magic 8.3.679,
this halving was done only for tech files whose extract section is in
microns (`units microns`, as in all the open PDKs);  8.3.679 added the
halving for all tech files when parsing the sidewall rules, so that
tech files in microns were halved twice and gave exactly half of the
coefficient (reported in github issue #557, item 1).  Requires the
version with the fix.

This test checks only that magic applies the coefficient it is given.  It
says nothing about whether the coefficient is correct:  the capiche values
in the open PDKs as of November 2026 are not (FasterCap stops on an
unconverged result for two closely spaced wires, 1.7 times too high at
minimum spacing for IHP sg13cmos5l metal3).  With correct coefficients,
the fixed halving matches OpenEMS for the IHP cap_cmomf capacitors of 10um
or larger to about 3%, so a dense structure does not need a separate
correction.

Also checks offsets that are not on the layout grid, which must be used
exactly:  a copy of the tech file is given offsets of 0.268 on metal1 and
-0.106 on metal5, with a tolerance of 0.1%.
