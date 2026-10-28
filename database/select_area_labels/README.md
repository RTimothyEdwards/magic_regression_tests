# What "select area" selects

The layout has, inside the box, a metal1 square with a label on it
("onmetal"), a label attached to space ("onspace"), and an instance of
another cell.  Each form of `select area` is followed by `move n 100`, and
the saved layout shows what was selected:

| Command                | metal1 | onmetal | onspace | instance |
|------------------------|--------|---------|---------|----------|
| `select area`          | yes    | yes     | yes     | yes      |
| `select area *`        | yes    | yes     | yes     | no       |
| `select area label`    | no     | yes     | yes     | no       |
| `select area m1`       | yes    | yes     | no      | no       |
| `select area m1,label` | yes    | yes     | no      | no       |
| `select area subcell`  | no     | no      | no      | yes      |

Background:  commit 51522d68 (August 2026, 8.3.679) made `select area
label` select labels attached to space and stopped it from selecting
unexpanded instances.  But `select area` (all layers) still did not select
labels attached to space, because the label search used the requested
layer types, from which space is removed.  Since magic 8.3.689, labels on
space are selected when no specific layers are requested (`select area
label`) or when all of them are (`select area`, `select area *`).  A
specific layer list (including `subcell`) selects only labels attached to
those layers.  The test requires 8.3.689.

With magic 8.3.688, `select area` and `select area *` do not select the
label on space.
