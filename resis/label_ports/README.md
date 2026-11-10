# Standard cell pin labels in R-C extraction

The pins of a standard cell are labeled from the cell's LEF definition, and
every labeled point is an equally valid connection point.  In sky130 `hd`
cells, the power pins are labeled over the whole rail, and other pins have
several labels.  Two problems showed up in R-C extraction of such a cell,
both fixed in magic 8.3.697, which the test requires:

1. **Label over a driving device.**  If a label covered the location of the
   device chosen as the driver of the net, the label's type replaced the
   device's type, and `extresist` looked for the device on the wrong plane:
   "Couldn't find device" and "Error in extracting node", and the net was
   not extracted.  In `inv_2`, the VGND label (on metal1, covering the rail)
   covers the lower left corner of an nfet.
2. **Several nodes with the same name.**  Each labeled point became a
   separate node with the pin's name, so the `.res.ext` file had several
   `rnode` records with the same name, resistors from a pin to itself, and
   unsimplified parallel resistors once those nodes were merged by name in
   the netlist.  Now nodes with the same name are merged during network
   simplification.

## What the test does

In sky130A, one `sky130_fd_sc_hd__inv_2` cell is placed, flattened, and
extracted with `extresist mindelay 0` and `extract do resistance`.  The
test checks that:

- there is no "Couldn't find device" or "Error in extracting node" message;
- VGND, VPWR and Y each have a network (`rnode` with the pin's name);
- no `rnode` name is written more than once;
- no `resist` record connects a node to itself.
