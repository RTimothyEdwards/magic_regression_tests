# Order of records in the .ext file

The output of `extresist` must not depend on the order of the records in the
.ext file, which can change between runs of `extract` (GitHub #538, #551).
Devices were sorted by the memory addresses of their nodes, so the choice
between two equal drivers of a net could change;  nets were processed in file
order, and the names given to device terminals by one net were used to sort
the devices of the next;  the ports of a net were used in file order;  and
coupling capacitance was summed in single precision in file order.

For each cell, the .ext file is copied with its records reversed, and in
three random orders,
and `extresist` is run on the copy.  If only the `cap` records are reordered,
the .res.ext file must be the same, byte for byte.  If records of every kind
are reordered, the networks must be the same, compared as sorted records with
the terminals of each resistor in sorted order:  the devices are written in
the order in which they were read.

`drivers` is two equal nfets with their own gates driving one wire from
opposite ends.  `mux4` is the flattened standard cell sky130_fd_sc_hd__mux4_4.
