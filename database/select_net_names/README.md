# "select net" connections through labels of the same name

Labels of the same name in one cell can connect parts of a net that are
not connected by drawn material.  Which ones do in the extracted netlist
depends on the "extract do unique" setting, and "select net" (and
"getnode") follow the same setting:

- `extract do unique` (the default):  none;
- `extract do unique notopports`:  ports of the same name in the top cell;
- `extract no unique`:  all labels of the same name, in any cell;
- in abstract views (cells with the "LEFview" property), all labels of
  the same name, whatever the setting, since extraction never makes
  their names unique.

Before this, "select net" followed ports of the same index in every cell
whatever the setting, and "getnode" followed none.  Each name that
connects material not otherwise connected now gives a warning.

## What the test does

In scmos, cell `sub` has two disconnected metal1 wires with port A and
two with label B;  cell `top` has the same with port C and label D, and
an instance of `sub`.  From one wire of each name, `select net` is run
with each setting, first as is and then with `sub` marked as an abstract
view.  The bounding box of each selection shows whether the other wire
of the same name was connected (`expected`), and each connection by name
must give one warning.  The expected results were checked against
extraction (`ext2spice` with `cthresh 0`, flat) with each setting.

`getnode` is also checked:  from a wire with label N, connected by name
to a wire that also has the top-level port P, it must give P with
`extract no unique` and N with `extract do unique`, without warnings.
