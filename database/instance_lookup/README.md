# Instance lookup by name

`instance list abutment <name>` (and the other `instance` options that take
an instance name, such as `position` and `orientation`) used to return an
empty result in two situations, both seen when a padframe script did:

```
getcell $padcell 270
identify $padname
set ibox [instance list abutment $padname]
```

1. **Timestamp mismatch.**  If the command was the first thing to read a
   cell whose timestamp did not match what its parent recorded, the mismatch
   was processed after the command, and the message "Processing timestamp
   mismatches." (printed through Tcl `puts`) replaced the command's result
   with an empty string.  Fixed in magic 8.3.695 by preserving the Tcl
   result around the mismatch processing after every command.
2. **Search order.**  The instance name was looked up by walking every
   loaded cell, reading each one from disk, and taking the first cell that
   had an instance of that name.  If that was not the edit cell, the command
   failed with "isn't a child of the edit cell".  Since 8.3.695 the name is
   looked up in the edit cell.

The test requires 8.3.695.

## What the test does

In scmos, cell `pad` with `FIXED_BBOX 0 0 20 20` is placed in `top` as `p1`,
rotated 90 degrees, so its abutment box in `top` is `0 -20 20 0`.  The
timestamp `top` records for `pad` is wrong.

- **Stale timestamp:** for each of `abutment`, `position` and `orientation`,
  a session loads `top` and calls `instance list <option> p1` twice.  The
  first call reads `pad` and causes the mismatch processing;  it must return
  the same value as the second.  The abutment box must be `0 -20 20 0`.
- **Same name elsewhere:** six other cells, each with an instance `p1` of a
  cell with a different `FIXED_BBOX`, are loaded before `top`.  `instance
  list abutment p1` must still return `0 -20 20 0`.  (With the old search
  the result depended on hash table order;  in practice it failed.)
