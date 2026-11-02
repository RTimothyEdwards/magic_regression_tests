# Ports remain in the extracted network

A 1um wide wire with ports IN and OUT at the ends and MID in the middle
(`common/resis_wire.tcl` with WIREMID=1).  Every port must be a distinct,
connected node of the resistor network, with half of the wire's
resistance between MID and each end (within 2%), and no subcircuit pin
may be left unconnected.  The cases are a 200um m1 wire (halves of 12.4
ohms) and a 20um m4 wire (halves of 0.45 ohms, below the default
`minres` of 1 ohm), the latter also with `minres` 2 ohms.

The network simplification removes resistors smaller than `minres` by
merging nodes, and removes a node between two such resistors in series.
With magic 8.3.691, MID on the m4 wire was merged into OUT.  The same
merging was behind a port that disappeared from the network (and was
then disconnected by a "killnode" in the .res.ext file) in an IHP inverter
(devel:extresist_open_net, netgen issue #108), which had been worked
around by never killing a port node;  the workaround in turn made the
port's original capacitance count twice once the capacitance was read
(see `cap_conservation`).  A resistor between two ports is now never
removed, and a port is never removed as a series node or by `mindelay`
pruning.

Requires 8.3.692.
