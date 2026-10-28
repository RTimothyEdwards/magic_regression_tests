# DEF special nets with several routed segments

GitHub issue #264:  `def read` handled several `+ ROUTED` (or `FIXED`,
`COVER`, `SHIELD`) segments on a regular net, but not on a special net.
For a special net, the second segment caused "Unknown keyword ROUTED in
SPECIALNET definition", the rest of the net was then misparsed as vias,
and all following special nets were lost.  Fixed in commit cb00ede5
(August 2023).  (Notes and the original test case in
`~/devel/magic/Haufe/DEF/`.)

## What the test does

`test.def` is the test case from the issue, extended with special nets
whose second segment is each of `FIXED`, `COVER` (followed by `ROUTED`
with a `NEW` segment), and `SHIELD`.  Magic reads the gf180mcuD
technology LEF (for the default width of the regular net's wires) and
`test.def`, and writes GDS.  The test fails if reading the DEF file gives
any error, warning, or message, and `check.py` checks that each special
net wire covers exactly the band given by its centerline and width
(allowing an extension of up to half the width at each end), and that the
regular net's two wires are present.

With magic 8.3.425 from just before the fix, the DEF file gives the
errors from the issue and every special net wire except the first is
missing.

Not covered:  `+ SHIELD` as the *first* segment of a special net is not
handled (see `TODO.md`).
