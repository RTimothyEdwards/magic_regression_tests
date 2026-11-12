# Netlist "ripup" and "verify" on split tiles

The netlist window commands trace connectivity with `DBSrConnect()`, which
reports each tile found with the side of a split (non-Manhattan) tile that
connects (`dinfo`).  The callbacks used `TiGetType()`, which always gives
the type of the left side of a split tile, so (fixed in 8.3.700, along with
the crashes of GitHub pull requests #554 and #561):

- `ripup` (and `cull`) erased the left-side type over the whole tile.  If
  the connected material was on the right side, it was left in place, and
  material of another net on the left side could be erased instead.
- `verify` (and netlist extraction) looked for terminals near the tile with
  the connectivity of the left-side type, which is space for a triangle on
  the right side, so a terminal on that triangle was reported as not
  connected.

## What the test does

In scmos, a metal1 wire ends at its left in a triangle on the right side
of a split tile, with space on the left side.  `ripup` from the wire must
leave no metal1 in the cell.  Then, with terminal A on the wire and B on
the triangle and a netlist with A and B in one net, `verify` must report
no wiring errors.
