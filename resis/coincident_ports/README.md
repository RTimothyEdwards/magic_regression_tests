# Two ports on the same point of an extracted wire

A 1000 µm × 0.5 µm metal1 wire has port A at its left end and ports A
and B on the same point at its right end (GitHub issue #597).  Since A
and B are at the same point, the extracted resistor network cannot
connect them.  The `equiv` between the two ports in the `.ext` file is
the only connection, and `ext2spice` must keep it:

- `short resistor`:  ports A and B, with a zero-ohm resistor between them;
- `short voltage`:  ports A and B, with a zero-volt source between them;
- `short none`:  A and B merged into a single port.

No port may be left unconnected, and the total capacitance must be the
same as without resistance extraction.

Each policy is checked with resistance extraction off, with zero
extraction thresholds, and with default thresholds.  The coincident
labels are made in both orders (A then B, and B then A), because the
order decides which name the `.ext` node gets and which name
`extresist` gives the network node at that point.

The test needs SKY130A and Python's standard library.
