# Coupling capacitance with extresist

Two neighboring wires are extracted with and without the resistor network.
The total capacitance to substrate and the total capacitance between the two
nets must each be the same in both netlists, within 0.5%.

Magic before this fix (8.3.695 as first pushed) added coupling capacitance to the
capacitance of both nets and wrote it as capacitance to substrate in `extresist`.

- `ports`:  the original nets keep their names, so the original coupling
  capacitor was also kept and the coupling was counted three times.
- `fets`:  the original nets are removed by "killnode", so the coupling
  capacitor was lost and replaced by capacitance to substrate on both nets.

This test only checks the totals.  Coupling capacitance is not divided along
the network:  each coupling capacitor has one node on each net.  With
`mindelay 1` these nets fall below the cutoff and are not given a network, so
those two cases only check that such nets are left unchanged.
