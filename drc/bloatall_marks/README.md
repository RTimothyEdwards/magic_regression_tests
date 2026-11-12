# Tile marks left by bloat-all and tagged

The CIF operators `bloat-all` and `tagged` find connected material by
marking tiles in the layout's own planes, and must clear the marks when
they are done.  The extractor uses the same tile field for its regions, so
a mark left behind is read as a region pointer, and `extract` after a
`drc check` that used such a rule crashed (GitHub issue #570, pull request
#572).

The marks were cleared only on the plane of the bloat types.  But the
search starts from seed tiles on every plane that has a seed type, so a
contact seed is also marked on its other plane (the metal1 plane here);
from there the search can spread into abutting tiles of a bloat type that
is also a contact;  and `tagged` had the same code for clearing marks.

## What the test does

`tiny.tech` (from the issue, extended) has two contacts, `psc` and `nsc`,
and three DRC styles with a CIF rule:

- `c1`:  `bloat-all psc psd`, a contact seed (the case in the issue);
- `c2`:  `bloat-all psc psd,nsc`, where the search spreads from the `psc`
  tile on the metal1 plane into the abutting `nsc` tile;
- `c3`:  `tagged VSS psc,psd`.

For each style, and for a style `plain` without the CIF rule, a layout
with abutting `psc` and `nsc` contacts, each with a port label, is checked
with `drc check` and then extracted.  Each extraction must finish, and its
.ext file must be the same as with `plain`.  Before the fix, all three CIF
styles crash in `extract`.
