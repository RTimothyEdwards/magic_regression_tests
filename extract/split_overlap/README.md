# Split-tile overlap and shielding

Area capacitance must use the intersection of the actual triangular
conductors, not the intersection of their rectangular bounding boxes.
Likewise, a split shield must be clipped against that intersection. A
blanket division of a clipped rectangle by two is not sufficient.

The test derives a temporary technology from SKY130A, retaining its layers,
connectivity and device rules but replacing capacitance rules with a single
1000 aF/µm² metal5-to-metal1 overlap coefficient. Metal2 and metal3 can
shield that coupling. Perimeter/fringe terms are excluded so every expected
coupling is an elementary area calculation, independent of PDK fitting.

Sixteen fixtures cover rectangles, aligned/complementary/crossing triangles,
partial overlap, unequal slopes, a single triangular or rectangular shield,
and the union of two shields on different planes. Each runs through all
eight rotations/reflections. A translated case brings the total to 129.
Expected areas are written explicitly; the test does not duplicate the C
polygon-clipping implementation. It also verifies that each label names
its drawn conductor rather than a separate zero-area sticky node.

Fixtures are generated as GDS with `common/gdslib.py`; no KLayout, Calibre,
external field solver, or third-party Python package is required.

This tests overlap area and port attachment, not the accuracy of a fringe
model or the whole non-Manhattan extractor. `resis/split_ports` separately
checks RC start points and zero-area ports.

This regression accompanies an unreleased source fix. The companion PR
must acquire a `require_magic_version` gate for the actual release carrying
that fix before it is merged.
