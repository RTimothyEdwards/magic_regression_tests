# extract_fringehalo

The fringe halo setting of `extract` selects a capacitance model.  Loading a
tech file turns it on for format 34 and higher, and off otherwise.  After that,
`extract do fringehalo` and `extract no fringehalo` are the only ways to change
it.  It used to be part of `extract do all` and `extract no all`
with no name of its own, so `extract no all` followed by `extract do capacitance`
and `extract do coupling` silently switched to the legacy fringe model.

The test extracts a metal2 wire over a metal1 plate with different option
sequences and compares the capacitors.  It checks that:

- `extract no all` produces no capacitors
- `extract no all` followed by turning capacitance and coupling back on, or by
  `extract do all`, matches the default options
- `extract no fringehalo` changes the result, `extract do fringehalo` restores
  it, and `extract no all` plus `extract do all` does not change the setting

It also checks the legacy model against hand calculation:  area * overlap
coefficient + perimeter * sideoverlap coefficient, for the wire above with
coefficients read from the sky130A tech file, and for poly over nwell in two
scmos styles (values from scmos.tech, in lambda).  One of those has `sidehalo 0`,
which always uses the legacy model.  The other is checked by default and with
`extract no fringehalo`, and `extract do fringehalo` must give a smaller value.
The cutoff is checked with the sky130A tech file changed to format 33 and 34,
a change of extract style must keep `extract no fringehalo`, and `tech load`
must replace the setting.  This model used to multiply by the side
halo in internal units as well, and was skipped altogether for `sidehalo 0`
edges with no sidewall rule.

Requires magic 8.3.694, the sky130A PDK, and the scmos tech file installed with magic.
