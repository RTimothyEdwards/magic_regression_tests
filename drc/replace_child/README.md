# Replacing an instance with one of a new cell

A DRC check of a cell copies up the errors of its children, so cells on
the DRC pending list must be checked after their children.  When the
device generator replaces a device with new parameters ("Apply" in the
parameter dialog), it deletes the old instance, which puts the parent on
the list;  then it draws a new cell, which goes on the list when it is
painted, before it has any parent;  then it places the new instance.
The parent stayed ahead of the new cell on the list, so it copied up
the new cell's errors before the new cell was checked, and the errors
were not shown (and the "DRC=" count was 0).  Now a cell that is already
on the list is moved to the end when it is put on the list again.

## What the test does

In scmos, cell `top` has an instance of a clean cell.  The instance is
deleted, a new cell with a metal1 width error is made, and an instance
of it is placed in `top`, in the same order as the device generator.
After `drc catchup`, the errors in `top` (`drc list count total`) and in
all cells (`drc listall count total`) must be non-zero and the same as
after rechecking all of `top`.
