# Reproducible extraction output

Running `extract` and `ext2spice` again on the same layout must write the same
files, byte for byte (GitHub #551).  Coupling capacitors are kept in hash
tables keyed by the addresses of node records, and were written in the order
of a search of the table, which changes from one run to the next;  the two
nodes of a capacitor were also written in order of address.

The layout is a few sky130 standard cells, one of them arrayed, under metal2
and metal3 wires, so that coupling capacitance is written for single cells,
for interactions between cells, and for arrays.  It is extracted three times,
in separate runs of magic, and every .ext and SPICE file must be the same in
all three.

The test relies on the addresses changing between runs, as they do when the
operating system randomizes addresses (the usual case on Linux).  If they do
not change, an older magic can pass.
