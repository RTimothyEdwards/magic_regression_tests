# CIF operators "overlapping", "interacting", and their inverses

The CIF operators `overlapping`, `nonoverlapping`, `interacting`, and
`noninteracting` keep each connected region of the layer being built
that does (or does not) overlap, or overlap or touch, the given magic or
CIF layers.  These all produced nothing at all, for three reasons:

- since magic 8.3.572, the regions were searched for in an area in magic
  units instead of CIF units, so that unless the scale factor was 1, the
  search usually found nothing;
- since magic 8.3.590, the regions found were never copied to the output
  (the push of each region's tiles was made conditional on the tiles not
  having been marked, after they were marked);
- touching material on a magic layer was missed when the CIF scale was
  not 1 (the one-unit expansion of the search was lost when scaling it
  back to magic units).

Also, the tech file reader crashed on these operators in a style where
the scale factor could be reduced.

## What the test does

A small technology (`tiny.tech`) has an output style with 50nm per magic
unit, so CIF and magic units are different, and layers made with each of
the four operators, once with the magic layer `poly` and once with the
CIF layer `P`.  The layout has three 10 x 10 metal1 squares, far from
the origin:  one overlapping poly, one abutting poly, and one with no
poly, and the same three at negative coordinates.  `cif coverage` gives
the area of each layer, and the number of squares in each (`expected`)
is checked:  overlapping keeps 2, interacting keeps 4, and each inverse
keeps the rest.
