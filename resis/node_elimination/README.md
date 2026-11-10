# Node elimination and resistor pruning

After the resistor network of a net is simplified, `extresist` eliminates
internal nodes (nodes that are not device terminals or ports) wherever this
does not increase the number of resistors, using the star-mesh transform
(the generalization of the wye-delta transform).  This is exact for the
resistance between the remaining nodes.  It removes the internal nodes of
via arrays drawn as individual cuts, whose loops cannot be reduced by the
series, parallel, and delta-wye combinations.  Eliminating nodes can create
resistors that carry a negligible part of the current;  such a resistor is
removed if another path between its two nodes, through at most one other
node, has less than the `extresist prune` tolerance (default 0.01) times
its resistance.  Added in magic 8.3.698, which the test requires.

## What the test does

In sky130A, a metal1 rail with eight ports (P0 to P7) runs under a metal2
strap with one port (S), and they are joined by three via arrays drawn as
individual via1 cuts, 6 x 6 and 12 x 12.  Each is extracted with
`extresist minres 0` (so that the approximate folding of small resistors
into their neighbors does not hide the result), once with the default
`prune` and once with `extresist prune 0`.  The test checks that:

- at most two internal (`.n`) nodes are left (there were 14 and 26 before
  node elimination was added);
- every port is in the network, and the network is connected;
- with the default `prune`, no resistor has a path of one or two other
  resistors between its nodes below 1% of its value;
- with `prune 0`, there are no fewer resistors than with the default, and
  for the 12 x 12 arrays there are more (in the 6 x 6 case, no resistor is
  negligible);
- `extresist prune` returns 0.01 by default, and an out-of-range value
  (1.5) is rejected without changing it.

These are structural checks only;  there is no independent reference for
the resistance values.  During development, the resistance between every
pair of ports was compared with the network before node elimination:
with `prune 0` they agreed within single-precision rounding, and with the
default `prune` within 0.1%.
