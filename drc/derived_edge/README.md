# Derived edge (contact cut) corner checks

Magic draws contacts as "derived" layers:  the contact type covers the
contact cut plus a border of the surrounding material on each side.  In
gf180mcuD the border is 5nm.  DRC rules that apply to the cut are written
against the contact type, with the rule distance reduced by the border
once for each side of the rule that is a cut.  For example, CO.3 (poly
overlap of contact >= 0.07um) is written as

    surround pc/a *poly 65 absence_illegal ...

That is exact for straight edges, but not for Euclidean corner-to-corner
measurements.  The contact type's corner is 5nm from the cut corner in
both x and y, or 7.07nm on the diagonal, so measuring from the corner of
the contact type with the reduced distance gives the wrong answer at
corners.  Magic corrects for this by measuring corner distances from the
corner of the cut (the `DRC_DERIVED_EDGE` and `DRC_DERIVED_TARGET` rule
flags in magic's `drc/` code).

A contact type is treated as a cut only when the rule does not also list
the contact's residue type.  Then `pc` in `spacing rpp pc` is a cut, but
`pc` in `spacing ... allpoly` (which includes poly) is just a poly edge.

## What the test does

Each case puts geometry at many offsets (A, B) around a corner and
compares magic's result with the correct result computed from the cut
geometry:

    error = max(0, A + bt)^2 + (B + bt)^2 < (d + bt)^2

Here d is the rule distance in the tech file and bt is the total border of
the sides that are cuts.  The offsets cover a band around the boundary
between error and no error, including straight-edge cases (A < 0).  Each
case runs against a copy of the gf180mcuD tech file whose DRC section has
only the rule being tested, because overlapping rules in the full deck can
hide each other's errors.

| Case | Rule | Cut sides |
|------|------|-----------|
| `pc_poly_{NE,NW,SW,SE}`, `pc_poly_1nm` | CO.3 surround | pc |
| `pdc_nwell` | DF.7 nwell surround of `*pdiff` | none (pdc is a diffusion edge) |
| `pcpc_ne`, `pcpc_nw`, `pcpc_ne_1nm` | CO.2a contact spacing | both |
| `rpp_pc`, `pc_rpp` | PRES.7 resistor to contact | pc |
| `pc_ndif`, `ndif_pc` | CO.8 poly contact to diffusion | pc |
| `ndc_pc`, `pc_ndc` | CO.7 diffusion contact to poly | ndc (pc is a poly edge) |

The `_1nm` cases use a 1nm internal grid (a copy of the tech file with
`gridlimit 1`) to check positions between manufacturing grid points.

## Expected result

All cases have zero false positives and zero false negatives.  Before
the fix, magic gave false positives at corners for every case with a cut
side.  The first version of the fix (surround rules only) gave false
negatives for `pdc_nwell`.
