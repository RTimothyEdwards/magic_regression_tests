# Length of a "tee" resistor

With `ext2spice resistor tee on`, a resistor is written as two devices in
series.  The lengths must add up to the length of the whole device, including
any offset in the device record of the tech file (GitHub #556);  the length
offset had been applied to each half.

Also, the flat writer (`ext2spice hierarchy off`) wrote only the first half of
a "device rsubcircuit" resistor, leaving the second terminal unconnected.

A device written after a tee resistor must keep its own length, so the case
`fet` draws FETs next to resistors in the same cell.
