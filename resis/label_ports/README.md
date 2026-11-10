# Standard cell pin labels in R-C extraction

The pins of a standard cell are labeled from the cell's LEF definition, and
every labeled point of a pin is an equally valid connection point.  In
sky130 `hd` cells, the power pins are labeled over the whole rail, and
other pins have several labels.  Labels that are not ports are only
annotations.  The rules for `extresist`, as of magic 8.3.697 (which the
test requires):

- A port is a connection point:  a node of the network with the port's
  name.  Ports with the same name are all the same node.
- A label that is not a port is ignored.  The net segment under it gets an
  ordinary subnode name (`.n` or `.t` suffix).  Flattening a cell removes
  the port flags from its labels, so this applies to a flattened standard
  cell, where the exact connections are known.

Fixed along the way:

1. **Label over a driving device.**  If a label covered the location of the
   device chosen as the driver of the net, the label's type replaced the
   device's type, and `extresist` looked for the device on the wrong plane:
   "Couldn't find device" and "Error in extracting node", and the net was
   not extracted.  This was found with a flattened `inv_2`, where the VGND
   label (on metal1, covering the rail) covers the lower left corner of an
   nfet.  Now that labels which are not ports are ignored, that case no
   longer reaches the code in question, and this test does not exercise it:
   a port label at the top level is itself the drive point.
2. **Several nodes with the same name.**  Each labeled point became a
   separate node with the label's name, so the `.res.ext` file had several
   `rnode` records with the same name, resistors from a pin to itself, and
   unsimplified parallel resistors once the nodes were merged by name in
   the netlist.  Now ports with the same name are merged during network
   simplification, and other labels are ignored.

## What the test does

In sky130A, with `extresist mindelay 0` and `extract do resistance`:

- **cell:** the `sky130_fd_sc_hd__inv_2` cell itself is extracted.  VGND,
  VPWR and Y must each have a node with the pin's name.
- **flat:** a flattened copy of the cell is extracted.  No node may be named
  after a label (for example `sky130_fd_sc_hd__inv_2_0.Y`);  each of VGND,
  VPWR and Y must have only subnodes (`.n` or `.t`).

In both cases, there must be no "Couldn't find device" or "Error in
extracting node" message, no `rnode` name written more than once, and no
`resist` record connecting a node to itself.
