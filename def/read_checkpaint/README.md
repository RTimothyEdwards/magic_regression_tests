# DRC check areas from LEF and DEF reads

A cell with new geometry that has not been checked gets `checkpaint`, however the
geometry arrived.  Before this, a LEF macro got it only if it had no SIZE, and a
DEF read never did.

| Read | Result |
|---|---|
| LEF macro, with or without a SIZE | `checkpaint` |
| DEF, with the DRC on or off | `checkpaint` |
| LEF annotating a cell that exists (a GDS view when installing a PDK) | none |
| DEF with `-annotate` on a clean cell | none |

Annotation only adds information to a cell, so the cell keeps whatever DRC state
it had.  That matters for PDKs:  their GDS views are read with `gds drccheck no`
and then annotated from LEF, and must be installed with no `checkpaint`.
