# Coupling capacitance to the body of a resistor

With `ext2spice resistor tee off`, the body of a resistor is not output as a
node, and its capacitance to substrate is split between the two terminals.
Coupling capacitance to the body must be treated the same way;  otherwise a
capacitor connects to a node that nothing else connects to (GitHub #559).

Two neighboring wires, each with a resistor in the middle, are checked with
"device resistor" (rmetal1) and "device rsubcircuit" (xhrpoly), with the tee
model on and off, and with hierarchical output on and off.  The total coupling
must equal the sum of the `cap` records in the .ext file, within 1%.

The sky130 tech file gives xhrpoly no coupling capacitance, so the `poly` case
adds a `cap` record between the two bodies to the .ext file before running
ext2spice.
