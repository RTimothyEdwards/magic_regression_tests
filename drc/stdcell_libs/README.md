# Standard cell library DRC

Runs DRC on every cell of these standard cell libraries:

- gf180mcuD: `gf180mcu_fd_sc_mcu9t5v0`, `gf180mcu_fd_sc_mcu7t5v0`
- sky130A: `sky130_fd_sc_hd`

It compares the errors in each cell (count and reason) against the
baseline in `expected/<library>.txt`.  The vendors have already checked
these libraries as DRC clean, so any error magic reports is either a
false positive in magic or a known exception.  The baseline currently
lists only the two sky130 tap cells (`tapvgnd_1`, `tapvgnd2_1`, metal1
minimum area).

Unlike the other tests, this one compares against magic's earlier output,
so it catches changes but does not say which result is correct.  The
results also depend on the installed PDK version.  After you have checked
that a difference is correct (for example, after a PDK update), regenerate
the baseline with:

    UPDATE=1 ./run.sh
