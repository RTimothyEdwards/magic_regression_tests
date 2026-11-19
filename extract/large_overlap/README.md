# Large overlap capacitance

Two identical square plates on metal1 and metal2 have a coupling capacitance
set by the nominal overlap coefficient times their area. The test reads this
coefficient from the installed SKY130 technology rather than hard-coding it,
then checks both `.ext` and SPICE capacitance for sides from 20um to 1000um.

The 231.70um and 231.71um cases straddle the signed 32-bit area boundary on
the default 0.005um internal grid. With a 32-bit intermediate product,
increasing the side by 0.01um makes the coupling capacitance disappear.
Larger cases also catch wrapped positive products that produce nonzero but
incorrect capacitance. The same geometry can be run under a build with
`-fsanitize=signed-integer-overflow` to identify the arithmetic failure.
See [Magic #583](https://github.com/RTimothyEdwards/magic/issues/583).

Requires the public SKY130 Magic technology files. No external extractor,
circuit simulator, or saved reference layout is needed.
