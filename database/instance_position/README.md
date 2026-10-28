# "instance position"

`instance position [name]` (added in magic 8.3.689) returns the position
of a cell instance:  the point in the parent cell where the origin of the
instance's cell is placed, which is the translation part of the
instance's transform.  Together with `instance orientation`, it gives the
whole placement of the instance.  The test requires 8.3.689.

## What the test does

In scmos, a cell whose layout is at (5, 5) to (20, 15) (so that the
position is not the lower left corner of the instance's bounding box) is
placed with `getcell` in five orientations (0, 90, h, 180, 270v) and once
as a 3 x 2 array, and the top cell is saved.  The test checks that:

- `instance position sub_N` for each instance equals the translation in
  the instance's `transform` line in the saved .mag file (for the array,
  that of the first element);
- `instance position sub_5[y][x]` gives the position of that element of
  the array (the first element's position plus the column and row
  pitches), and so does `instance position` after `select cell
  sub_5[1][2]` (the whole array is selected, but the element is
  remembered);
- with one instance selected, `instance position` returns the same "x y";
- with all instances selected, it returns the list of {x y} pairs;
- after `scalegrid 1 2`, the position in internal units is exactly twice
  the position in lambda (the values follow the `units` setting).
