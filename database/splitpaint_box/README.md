# "splitpaint" and "spliterase" with a zero-size box or a locked layer

GitHub issues #94 and #95 (Mark Martin), fixed in commits 6b72a51b and
e670dd97 (November 2021, magic 8.3.231):

- `splitpaint` with a zero-size box could crash, or paint a triangle with
  vertices at infinity;  `spliterase` with a zero-size box erased half of
  the shape under it.
- `splitpaint` and `spliterase` ignored layer locking (`tech lock`).

## What the test does

In scmos, `split.tcl` does each of these and saves the cell after each
step, and `run.sh` checks the saved paint:  nothing painted or erased
with a zero-size box, and the locked layer unchanged.

With magic 8.3.230 (before both fixes, built with `-fpermissive` because
2021 code does not compile with gcc 14 otherwise), every step fails:  the
zero-size `splitpaint` makes a triangle from (-1073741818, -1073741818)
to (1073741820, 1073741820).
