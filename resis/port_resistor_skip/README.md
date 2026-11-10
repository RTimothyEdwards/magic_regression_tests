# Resistor network simplification with skipped resistors

`extresist` simplifies each net's resistor network by repeatedly taking the
smallest resistor below the threshold and merging it into its smallest
neighbor.  Since magic 8.3.692, a resistor between two ports (or a port
and the driving point) is skipped instead of merged, so that no port name
is lost.  The resistor merged away is then not always the first in the
sorted list, and its neighbor may be.  The code that unlinked the neighbor
from the list assumed it had a predecessor, and magic crashed (segfault in
`ResScrunchNet()`).  This was reported with two abutted IHP inverters,
flattened and extracted with `extresist mindelay 0`;  raising `extresist
minres` avoided it.  Fixed in 8.3.697, which the test requires.

## What the test does

In sky130A, two `sky130_fd_sc_hd__inv_2` cells are placed side by side
(abutment boxes touching), the top cell is flattened, and the flattened
cell is extracted with `extresist mindelay 0` and `extract do resistance`.
Magic must finish and write `top_flat.res.ext`.  (Magic also reports
"Couldn't find device" for one transistor of the ground net;  that is a
separate problem, not checked here.)
