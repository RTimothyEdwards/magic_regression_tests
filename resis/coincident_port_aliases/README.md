# Coincident port aliases in full R-C extraction

Coincident named ports must remain electrically connected when extresist
merges their internal nodes. Before the fix, one port name could be lost
from `.res.ext` while remaining as a floating formal terminal in SPICE.
Replaying all original `.ext` equivs is not a fix: that bypasses legitimate
finite wire resistance (magic issue #587).

The test uses the unmodified SKY130A technology and Python's standard
library. An independent straight-wire model computes R from sheet
resistance, contact positions and width, with explicit ideal ties only at
coincident contacts or repeated external port names. It checks every
port pair, including isolation between metal1 and metal2 at identical
coordinates without a via.

Nine fixtures cover distinct ports, two/three coincident names, a repeated
port at the far end or middle, chained aliases, near-but-distinct ports,
ordinary repeated annotations and separate conductors. Reversing the label
records, toggling simplify and all three short policies gives 108 cases.
Each also compares total capacitance against its C-only extraction. A
retained formal terminal with no element incidence is always a failure.
For `short none`, a removed alias may be resolved only from an explicit
physical `.res.ext` equiv; topology-only `.ext` equivs never repair RC
connectivity in this test.

The paired test PR stays draft until the source fix receives an upstream
release number. Add `require_magic_version` with the actual containing
version before merge, rather than guessing a future version or skipping
based on whether the test detects the bug.
