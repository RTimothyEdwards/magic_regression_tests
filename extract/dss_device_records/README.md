# Several device records for one model

GF180MCU's DSS (drain-side salicided) FETs have a salicide block
(`ndiffres`) on one or both sides of the gate, and both kinds use the same
model.  A tech file can describe them with two `device` records for
`nfet_03v3_dss` that differ in their terminal types (`ndiffres ndiffres`
and `*ndiff ndiffres`) and in their parameters (the one-sided record
zeroes the SAB length of the `ndiff` side).

`layout.mag` has one device of each kind.  The test makes four variants of
the GF180MCU tech file, with the two records in either order and the
one-sided record written both ways round, and checks for each that:

- both devices are extracted, each with two different terminal nets;
- the two-sided device has the SAB length (the width of the `ndiffres`
  region) on both terminals;
- the one-sided device has the SAB length on the `ndiffres` side, zero on
  the `ndiff` side, and the right gate length;
- no extractor-internal record name (`model@n`) reaches the netlist.

Expected lengths come from the layout geometry:  gates are 14 units long
and the `ndiffres` regions 9 units wide.

Previously the matching record could be lost when the perimeter search
switched records, depending on record order, and `ext2spice` applied the
parameters of the first record to every device of the model.

The test needs gf180mcuD and Python's standard library.
