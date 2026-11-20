# Port short policies with resistance extraction

With `ext2spice extresist on`, an `equiv` between ports of the same
conductor must not create an ideal connection in parallel with the
extracted resistor network. Both `short resistor` and `short voltage`
previously bypassed the physical resistance. `short none` did not.

The fixture has a 2000 µm × 0.5 µm metal1 wire with three ports and a
separate 100 µm × 2.5 µm metal2 wire. Expected port resistances come from
the geometry and the technology's sheet resistance. The checker contracts
zero-ohm resistors and zero-volt sources, then solves the remaining
conductance network; merely counting finite resistors would miss the bug.

All three short policies are checked with:

- resistance extraction disabled;
- zero extraction and reduction thresholds;
- default thresholds, which extract the long wire but skip the short one;
- resistance extraction enabled but its `.res.ext` file absent.

The last two cases ensure that deferred aliases still connect unextracted
ports. The two wires must remain isolated. A removed ideal-wire alias is
recognized only if it is absent from both the native ports and elements;
the checker never reconnects a retained floating port.

The test needs SKY130A and Python's standard library. It does not simulate
transistors or require NumPy.

This regression accompanies an unreleased source fix. The companion PR
must acquire a `require_magic_version` gate for the actual release carrying
that fix before it is merged.
