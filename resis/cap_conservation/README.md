# Total capacitance with extresist

`extresist` distributes the capacitance of a net over the nodes of its
resistor network.  The total must equal the capacitance of the same net
without extresist.  Each case is a wire (`common/resis_wire.tcl` with
WIRECAPS=1, which writes the netlist both with and without the extresist
network, with all capacitors);  the sums of the capacitors must agree
within 0.5%.

Magic 8.3.691 passes, but only because it did not read the capacitance
of the net from the .ext file, so all of it stayed on the original node
(at one end of the wire) and none was distributed.  When the
capacitance is distributed, the original node is not removed if one of
the network's nodes has its name (such as a port), so it keeps its
original capacitance from the .ext file;  that amount must then be
subtracted from the network node of the same name, or the capacitance
is counted twice.
