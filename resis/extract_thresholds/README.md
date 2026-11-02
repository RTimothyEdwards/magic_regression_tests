# Which nets extresist extracts

The `extresist` options `threshold` (minimum network resistance, in
milliohms) and `mindelay` (minimum network delay, in picoseconds) decide
which nets are extracted as resistor networks.  The intended rules:  a
zero value is no cutoff;  if both are set, a net must exceed both;  the
same rules apply to the lumped estimate from the .ext file (whether to
extract the net) and to the extracted network (whether to output it).  A
net that is not extracted must come out as it would without extresist:
one node, with shorted ports merged.

Each case is a wire with ports IN and OUT (`common/resis_wire.tcl`) whose
resistance is known (squares times sheet resistance) and whose delay is
known roughly (RC/2):  a 100um m1 wire (12.4 ohms, well under 1ps), a
10um m4 wire (0.42 ohms, which the .ext file rounds to 0 ohms), and a
100um li wire (1267 ohms, about 12fF, several ps).  For each setting the
test checks whether the net was extracted, and either that the network
has the wire's resistance (within 2%) or that IN and OUT were not left as
two unconnected pins.

With magic 8.3.691, 9 of the 10 cases fail (github issue #568):

- Every port node was given zero path resistance, so a two-port net had
  a network resistance of zero and was dropped by any nonzero threshold.
- A zero threshold still required the lumped resistance (in whole ohms,
  without contact resistance) to be greater than zero.
- The node capacitance was not read from the .ext file, so every delay
  was zero, and with `mindelay` the network was pruned down to a 0 ohm
  resistor.
- A net that was not extracted was written with its ports as separate,
  unconnected pins.

Requires 8.3.692.
