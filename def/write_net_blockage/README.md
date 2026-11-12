# "def write" with an unlabeled net

`def write` writes nets that have no port or special net as blockages, if
the technology file has a "lef" section.  The geometry of each such net is
found with `DBSrConnect()`, whose callback had not been given the split
tile argument (`dinfo`) added in magic 8.3.590, so its arguments were
shifted and it dereferenced the plane number as a pointer.  `def write`
crashed on any layout with an unlabeled net, from 8.3.590 to 8.3.699.

## What the test does

In sky130A, two metal1 wires are drawn:  one with a port label and one
without.  After `extract all` and `def write`, the DEF file must have
exactly one blockage, the unlabeled wire (2um by 0.2um at the origin).
