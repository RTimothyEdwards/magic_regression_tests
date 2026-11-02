# Resistance of a straight wire

A 100um x 1um wire on each sky130 routing layer (li, m1 to m5), with ports
IN and OUT as 1um squares at the two ends, extracted with `extresist`
with `threshold`, `mindelay`, and `minres` all zero.  Magic measures
resistance between the centers of the ports, so the expected resistance
is 99 squares times the sheet resistance of the layer, which is read
from the nominal (first) `resist` line of the extract section of the tech
file.  `common/spicenet.py` computes the effective resistance between IN
and OUT from the resistors in the netlist, so the result does not depend
on how magic divides the wire into resistors.  It must be within 1%.

This is the baseline for the other `resis/` tests:  it passes with magic
8.3.691, where the simplest case already worked.  The wire is drawn by
`common/resis_wire.tcl`.
