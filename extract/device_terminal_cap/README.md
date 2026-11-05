# Capacitance on device terminals

The "pi" resistor model moves the capacitance of a resistor's body (its
first terminal, which does not appear in the netlist) evenly to its two
ends.  That must apply only to resistors.  For any other device, the first
terminal is a real one, such as the gate of a MOSFET, and its capacitance
must stay where it is.

Each case is a `.ext` file, so nothing here depends on the extractor.  The
expected values come from the `node` and `cap` records in the file, and must
be the same from the hierarchical and the flat writers.  `sky130a_diode` and
`sky130a_inverter` are from GitHub issue #553.

Before magic 8.3.694, the hierarchical writer applied the pi model to all
subcircuit devices:  The gate capacitance of a MOSFET was moved to its source
and drain, and the capacitance of a diode was moved to the substrate and
lost.  The flat writer did the same for `subckt` and `csubckt` devices with
three or more terminals.

This does not cover `ext2spice resistor tee on`.
