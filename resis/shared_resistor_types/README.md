# Shared resistor model names

IHP SG13G2 defines ideal resistors on seven metal layers with the same model
name, `None`. A name-only lookup selects the first layer, so RC extraction
misses the devices on the other layers. When the devices have the same XY
location, the netlist device key can also merge seven independent resistors
into one. See [Magic #577](https://github.com/RTimothyEdwards/magic/issues/577).

The test draws seven 2um-wide wires, each 30um long with a 6um resistor body
and a port at each end. It checks separate and coincident placements under
four rotations and two reflections. All seven paths must conduct, remain
isolated from the other layers, retain nonzero extracted leads at all fourteen
ports, and have the expected end-to-end resistance from the drawn dimensions.
Original extraction must report all seven devices using the shared model name.
Both extracted wire segmentation and element ordering may vary.

Requires the public IHP SG13G2 Magic technology files; no device models or
external circuit simulator are needed.
