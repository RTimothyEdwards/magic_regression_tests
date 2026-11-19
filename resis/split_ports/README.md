# Ports on split tiles

An interior label on a triangular conductor must select that conductor's
half of the tile. The RC start-point lookup must make the same choice.
Point ports on diagonal or tile boundaries must also be included when
building the resistor network, without moving their actual breakpoints.

The test generates a triangle with interior ports, a triangle with ports
on its diagonal, and a diagonal wire. In every rotation and reflection,
the extracted ports must have a finite positive resistance and preserve
the lumped net's total capacitance. Negative controls put a label in the
empty half of a triangular tile; that label must remain separate. There
are 32 cases, all using the unmodified SKY130A technology.

The checker rejects extraction error messages even if Magic exits zero
and writes a SPICE file. A renamed or missing pin cannot substitute for
the two requested ports. It uses the existing `common/spicenet.py`
conductance solver and Python's standard library.

This checks connectivity and capacitance preservation. It does not claim
that Magic's existing simplified diagonal-wire resistance model is a
field-solver reference.

This regression accompanies an unreleased source fix. The companion PR
must acquire a `require_magic_version` gate for the actual release carrying
that fix before it is merged.
