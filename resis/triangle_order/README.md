# Repeatable triangle-to-Y simplification

The resistor network from repeated `extresist` runs on the same layout
must be independent of heap addresses.  The high-degree path of
`ResTriangleCheck()` searched a hash table keyed by node pointers, so
the first triangle chosen could change between runs.  Subsequent
triangle-to-Y conversions and rounding then changed the extracted
network, including resistor values and internal node locations.

## Layout and checks

The case uses Magic's built-in SCMOS technology; no external PDK is
needed.  A vertical metal1 rail crosses a horizontal metal2 strap, each
with a port at either end.  A row of separate via cuts connects them.
The metal1 side of the cuts shares one internal node; the metal2 sides
form a chain.  There are therefore several possible triangles at the
shared node.

The cases have 0, 7, 8 and 12 cuts:

- 0 cuts: two separate wires, with no triangles.
- 7 cuts: the shared node has 9 connections, below the hash threshold.
- 8 cuts: 10 connections, exactly at the hash threshold.
- 12 cuts: 14 connections, with several triangle choices.

Each case is drawn and extracted in 16 fresh Magic processes.  A live
Tcl string of a different size perturbs heap allocation before drawing;
the geometry, labels and extraction settings stay the same.  The test
uses the real `extresist` command and the resulting `.res.ext` file.

Every run must complete, retain all four ports, and contain finite,
positive resistors with declared endpoints.  The ports must be connected
as specified by the layout: A to B and C to D separately without cuts,
and all four together with cuts.  Internal components without a port are
rejected.  Normalized extraction records must then match between runs;
normalization ignores record order and resistor endpoint direction, but
preserves node names, locations and values.

Run with:

```sh
MAGIC=/path/to/magic ./resis/triangle_order/run.sh
```

The test requires Magic 8.3.697, the version of the source tree targeted
by the accompanying fix.  The unmodified 8.3.697 and the fixed build have
the same version string, so this version check does not hide the defect.
