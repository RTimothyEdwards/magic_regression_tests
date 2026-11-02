# Contact resistance of via chains

`gen_vias.py` writes a cell for each sky130 via level (li-m1, m1-m2,
m2-m3, m3-m4, m4-m5) and number of cuts N = 1, 2, 4, 8:  a lower metal
arm with port `l`, an upper metal arm with port `u`, 16um wide, and N cuts
in one column where they overlap.  The metal is the same in every cell
of a level, so R(1) - R(N) depends only on the cuts:  it must be the
resistance per cut (from the `contact` line of the tech file's extract
section) times (1 - 1/N), within 1% of one cut.  The chains are extracted
with all cutoffs at zero.  (The structure follows the via chains of the
PEX bench in iic-jku/open-pdks-regression-tests, which found the problem.)

With magic 8.3.691, only li-m1 is extracted.  The other levels have a
lumped resistance under 1 ohm (the via resistance is not included in the
lumped estimate), which the .ext file writes as 0, and a zero threshold
still required it to be greater than zero:  no resistor was output, and
port `l` was left unconnected (github issue #568).

Requires 8.3.692.
