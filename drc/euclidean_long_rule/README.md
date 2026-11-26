# Euclidean distance for long DRC rules

With `drc euclidean on`, magic checks the corner-to-corner distance of a
spacing rule as a true (Euclidean) distance.  The rule distance and the bits
marking which corner directions to check were kept in one `int`, with the
mask bits starting at bit 12.  So any rule distance of 4096 internal units
or more ran into the mask bits, the Euclidean check failed, and the rule
fell back to Manhattan distance, giving false errors at corners.  The mask
bits are now at the top of the word.  (GitHub issue #600, fixed in magic
8.3.709.)

The issue was found with IHP sg13g2 rule Padb.b, solder bump spacing of
70 um (7000 internal units).

## What the test does

Each case is a pair of 6000 x 6000 solder pads placed corner to corner,
offset by the same gap in x and y.  With Euclidean distance the corners are
gap * sqrt(2) apart, and without it they are gap apart.  The expected
result is an error exactly when that distance is less than 7000.  Only
Padb.b errors are counted (the pads have no metal 7, so there are also
unrelated Padb.c errors).

| Cell    | Gap  | Euclidean | Distance | Error expected |
|---------|------|-----------|----------|----------------|
| s5500   | 5500 | on        | 7778     | no (failed before the fix) |
| s5500   | 5500 | off       | 5500     | yes            |
| g4900   | 4900 | on        | 6930     | yes            |
| g5000   | 5000 | on        | 7071     | no (failed before the fix) |

`s5500.mag` is the layout from the issue.  The other two cells are made by
the test script;  `solder` is a locked type in the tech file, so the script
unlocks it first.  The two cases with an expected error check that the rule
is being applied at all.
