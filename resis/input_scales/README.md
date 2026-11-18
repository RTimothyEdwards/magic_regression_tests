# Units in existing extraction files

Two parallel sky130 metal1 wires are extracted once. Copies of that same
.ext file express exactly the same physical capacitance using scale factors
1, 10, and 1000. Ordinary ext2spice must produce the same reference network,
and extresist must produce the same distributed R/C network. Comparing only
total capacitance would miss the bug: capacitance can move between resistance
nodes while the total remains unchanged.

Before the paired fix, a 1.4089 fF terminal capacitor becomes 0.14089 fF or
0.00141 fF when only its input units change. ResReadNode and
ResReadCapacitor read raw capacitance without applying the .ext scale.
The test also checks that changing resistance units preserves the decision
to skip a wire whose estimated resistance is below the extraction cutoff.

Both retained port nodes and replaced transistor drain nodes are tested.
The latter requires exporting coupling capacitors into the .res.ext file.
For each layout, a copy of the technology file changes only output cscale
by a factor of 1000; the physical R/C network and transistor parameters must
remain unchanged. This also checks conversion from internal aF units to
the output file's units, independently of the input file's units.

Generated inputs, native logs, and all netlists remain in work/ on failure.
