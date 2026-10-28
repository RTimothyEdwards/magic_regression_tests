# To do

## Survey of past issues (done 2026-10-27)

Go through the places where past issues have been described and write
down a list of regression tests to implement.  For each one, record:

- what to test (command, subsystem, expected behavior);
- where the information and example files are (directory, issue or PR
  number);
- whether the issue is fixed (a test should pass) or still open (a test
  would document the bug);
- which PDK or tech file it needs.

The list is below, under "Tests to implement".  Work through it a couple
of items at a time, starting with the [A] items.

## Note:  running old versions of magic

To check that a test catches a bug, build the version before the fix in a
separate directory with `./configure --prefix=<dir>`, `make`, `make
install`, and run the test with `MAGIC=<dir>/bin/magic`.  Do not stage an
old version with `make install DESTDIR=...` and CAD_ROOT:  before some
point in 2026, `magicdnull` and `magicexec` load `magic.tcl` (and so the
magic library) from the compiled-in install directory, so the staged copy
silently runs whatever is installed in /usr/local.  Check the "revision"
line at startup.

## Sources of test cases

1. **Issue test cases in `/home/tim/devel/magic/`**:  about 175
   directories, mostly named after the person who reported the issue
   (e.g. `Torleif/extresist_alloc_error/` for issue #539).  This is
   probably the richest source, since most directories have example
   layout files.
2. **GitHub issues and pull requests** at
   https://github.com/RTimothyEdwards/magic/issues and `.../pulls`.
   These overlap a lot with (1).  Many issues are resolved but still
   open, because pull requests are not merged on GitHub and so do not
   close issues automatically.  An open issue is not necessarily still
   a problem; check whether Tim has said it was fixed.
3. **The old "vezzal" CI tests** by Sai Charan Lanka (2021).  Magic's
   `.github/workflows/main.yml` (created in commit 13b1c943, 2021-08-23)
   pulled the Docker image `vezzal/vezzal:v1` and ran
   `/vezzal/test_magic.sh` inside it, mailing the results.  The tests
   were inside the Docker image, not in the magic repository.  The task
   was removed in commit 88ca77f6 (2026-03-25, "GHA: main.yml: remove
   vezzal task").  Check whether the image is still on Docker Hub (or
   whether a VEZZAL source repository exists) and copy over any useful
   tests.  The current workflows only build magic on different
   platforms.
4. **The WASM/npm examples in magic's `npm/examples/`** (commit 7c71d0f3,
   2026-05-21):  small scripts for extraction, GDS, CIF, DRC, and PCell
   generation on `min.mag` (scmos), run in CI for both WebAssembly
   variants (`npm test`, `npm run test:tcl` in `main-wasm.yml`).  They
   check only that the commands run and produce output.  See "Possible
   task" below.

## Possible task:  share tests with the WebAssembly build

Ideally the WebAssembly CI would run tests from this repository instead
of keeping its own in `npm/examples/`.  This is on hold:  Tim will ask the
WASM build authors for their opinion first.  Things learned so far:

- `npm/examples/` is also user documentation:  the npm package ships it,
  and the npm README tells users to run the examples and use `helpers.js`.
  So some usage example probably has to stay there.  (`example.js`
  imports `../magic.js`, which no longer exists since the build was split
  into `tcl/` and `notcl/` variants, so it looks broken.)
- The WebAssembly build has no shell and an in-memory file system (no
  NODEFS), and CI has no PDKs.  So it cannot run the `run.sh` scripts
  here.  It can run a Tcl script after the JavaScript wrapper copies the
  needed files into its file system.
- A possible design:  write scmos-based tests as plain magic Tcl scripts
  that print their own PASS/FAIL, run them natively from `run.sh`, and add
  a small node runner here that copies a test's files into the WASM file
  system and runs the same script.  `main-wasm.yml` would check out this
  repository and run that runner.
- Building and testing the WASM side needs emsdk and node, which are not
  installed on Tim's machine.

## Related task:  triage open GitHub issues

Many of the open issues at https://github.com/RTimothyEdwards/magic/issues
are already fixed.  Go through them and decide for each whether it can be
closed or still needs work.  This fits with the survey above:  writing a
test for an issue is a good way to confirm it is fixed before closing it,
and the issues that are still open become tests that document the bug.

Open issues (as of 2026-10-27) where Tim's last comment says the problem
was fixed, or the reporter confirmed it:  #28, #39, #94, #95, #104, #105,
#106, #107, #127, #134, #147, #163, #188, #196, #223, #243, #251, #298,
#304, #309, #318, #366, #457, #488, #532.  #549 is a duplicate of #470.
These look closable;  the ones with an [A] test above can be closed once
the test passes.

## Tests to implement

Surveyed on 2026-10-27 from the sources above:  the notes in
`/home/tim/devel/magic/` (named `devel:` below), the GitHub issues (`#N`),
and the old VEZZAL tests.  "Fixed" and "open" are taken from the notes and
issue comments and should be confirmed when the test is written.  Each
entry gives a proposed test name, what to check, the source, and the
PDK.  Items are marked:

- **[A]**  fixed, with a small example or a short recipe:  write these first.
- **[B]**  fixed, but the only example is a large design that would need
  to be reduced to a small test case first.
- **[C]**  still open (or status unclear):  the test documents the bug, and
  is expected to fail until it is fixed.

Not listed:  issues that turned out to be user errors, PDK errors (fixed in
open_pdks), problems in other tools (klayout, netgen, OpenROAD), build and
installation problems, and questions.

### Database, editing, and commands

(Not worth testing:  specific tile plane corruption bugs, such as the
"stretch" corruption of 2025 in devel:corruption.  There are too many
possibilities, and the effects of corruption are hard to predict.)

- **[C]** `select more cell <instance>` fails (#295);  `select area` with
  several contact layers fails (#504).  (`select area subcell` selecting
  only unexpanded instances is intended:  the February 2025 change to
  select expanded instances too was reverted in commit 2630ebcd, August
  2025, so no test for it.)
- **[A]** `database/maskhints_overflow`:  a large number of mask hints
  overflowed a string buffer when read back from a .mag file
  (devel:Vicente/scripting, fixed 2023).  Mask hints are now a "plane"
  property, so check whether this still applies.
- **[A]** `database/units_save`:  `units` with FIXED_BBOX gave a property
  command missing a key, and `save <x>.tcl` misreported the file name
  (devel:units, fixed 2026-03).
- **[C]** `database/undo_properties`:  changing instance properties
  (Ctrl+P, gencell parameters) corrupts the undo stack (#501,
  devel:Nematallah).  Open.
- **[C]** `database/writeall_scaled`:  `writeall force` with unexpanded
  subcells corrupts cells when the PDK uses scaling (#518).  Open, no
  response yet.
- **[C]** `database/long_home_rcfile`:  buffer overflow when HOME is very
  long and `-rcfile` is relative (#489, includes a reproducer script).
  Open.
- **[C]** `database/unicode_path`:  cell name check applied to the whole
  path, failing on non-ASCII home directories (#216).  Open.
- **[C]** `database/tech_include`:  `include` in tech files does not find
  relative or absolute paths (#303).  Open, no response yet.
- **[C]** `database/load_dereference`:  `load -dereference` of a .mag
  outside the current directory fails (#231).  Status unclear.

### DRC

- **[A]** `drc/vezzal_rules`:  the VEZZAL "case4" tests:  small sky130A
  layouts `met1.mag` to `met5.mag` and `via1.mag` to `via4.mag` with
  expected DRC reports (saicharan0112/vezzal on GitHub,
  `regression/testcases/magic/case4`).  Copy and update the expected
  results (check the license:  GPL-3 per the README).  sky130A.
- **[A]** `drc/cifmaxwidth_split`:  `cifmaxwidth` flagged false errors on
  split tiles (devel:Mark/DRC_on_45s, fixed 2025-08).
- **[A]** `drc/trigger_clip`:  false deep-nwell spacing errors from
  trigger rules not clipped to the check area (devel:Reda/dnwell, fixed
  2023-08).  sky130A.
- **[A]** `drc/offlayout_errors`:  DRC errors outside the layout, heading
  off to infinity, from an invalid clip area (devel:spurious_drc, fixed
  2026-03).  ihp-sg13cmos5l.
- **[B]** `drc/runlength`:  wide-metal run-length errors missed
  (devel:runlength, fixed 2026-04).  ihp-sg13cmos5l.
- **[B]** `drc/noninteracting`:  latch-up rule (LU.c, pSD.i/j) false
  errors from the "noninteracting" operator (devel:Leo/latchup_error has
  `counter.gds`, fixed 2025-12).  ihp-sg13cmos5l or sg13g2.
- **[C]** `drc/bloat_all_dist`:  `bloat-all ... <dist>` results not
  rotationally symmetric (devel:Mark/bloat_dist has a reduced
  `small_test`).  Status unclear;  also a DRC run time issue
  (devel:bloat_all_dist/ihp_tests).
- **[C]** `drc/overlap_enclosed`:  disallowed overlap between cells is not
  flagged when one shape completely covers the other (#302).  Open.
- **[C]** `drc/subcell_why`:  `drc why` on errors in subcells
  (devel:drc_subcell).  Status unclear.

### CIF and GDS input and output

- **[A]** `cif/gds_nonmanhattan`:  GDS write and read-back of
  non-Manhattan shapes at various angles (devel:fixsides, after the TT_SIDE
  change, fixed 2026-01).  scmos.
- **[A]** `cif/gds_instance_names`:  instance names lost on .mag to GDS to
  .mag (#196, fixed 8.3.340).
- **[A]** `cif/gds_port_index`:  a very large port index made GDS output
  take forever (devel:Juan/gds_issue, fixed).
- **[C]** `cif/gds_cell_names`:  GDS cell names that differ only in case
  (#126) and names with many `$` (#97).  No response yet on either.
- **[A]** `cif/cif_hier_property`:  the CIFhier property forces
  hierarchical processing (devel:cif_hier, 2023).
- **[C]** `cif/gds_label_newline`:  labels containing a newline break the
  saved .mag file (#397).  Status unclear.
- **[C]** `cif/contact_no_cuts`:  a contact area that passes DRC but has no
  room for any cut should be an error (devel:no_contact_area;  related
  #247).  Open.
- **[C]** `cif/bridge`:  the `bridge` operator behaves differently at
  different levels of the hierarchy (devel:Sylvain/extra_psdm,
  devel:Sylvain/hvntm).  Open.

### Extraction

- **[A]** `extract/sd_area_perim`:  source/drain area and perimeter were
  zero in scmos (devel:Claudio, devel:ext2spice;  fixed).  Related:  two
  diode-connected FETs sharing source and drain (#237).  scmos and sky130A.
- **[A]** `extract/port_label_choice`:  a non-port label was chosen over a
  port label (#243, devel:Mitch/issue_243;  fixed 8.3.408), and the
  default substrate name VSUBS was chosen over the label "ground"
  (devel:Leo/vsubs_pin, devel:Aleksandar;  fixed 2026-02).  sky130A.
- **[A]** `extract/abstract_instance`:  an abstract cell with no devices
  (a logo) was defined in the netlist but not instanced
  (devel:Leo/logo_issue, fixed 2026-03).
- **[A]** `extract/subcell_substrate`:  a subcell extracted by itself had
  capacitors to "0" instead of the substrate node (devel:Igor, fixed
  2026-02).  sky130A.
- **[A]** `extract/isolated_pwell_label`:  a label on pwell inside deep
  nwell shorted the isolated pwell to the substrate
  (devel:Mark/labeled_iso, fixed 2026-07), and the double free that the fix
  caused (devel:Mark/shaper_extract).  sky130A.
- **[A]** `extract/floating_label`:  a floating label disconnected a pin
  (devel:Mitch/floating_label_error, fixed 2026-03).
- **[A]** `extract/unique_notopports`:  `extract unique notopports` merged
  two differently-placed labels with the same name (devel:Mitch/issue_186,
  fixed 2022).  [C] #317 reports a later regression:  check.
- **[A]** `extract/hierarchy_off`:  `ext2spice hierarchy off` did not
  flatten a wrapper subcircuit around a primitive device (#298,
  devel:Robin;  fixed 8.3.468).  sky130A.
- **[A]** `extract/device_params`:  `device bjt` (and FET) parameters off
  by one (`argstart` in efBuildDevice, devel:Mitch/bjt_extraction, fixed
  2026-01, IHP);  duplicated parameters (#223, #251, fixed).
- **[A]** `extract/name_mangling`:  instance names containing `/` (#70) and
  cell names starting with a digit (#71).  Fixed 2021.
- **[A]** `extract/param_roundoff`:  parameter values printed with
  round-off error (devel:Mark/roundoff_error, fixed 2025-01).
- **[B]** `extract/flattened_io_ports`:  8.3.585 dropped ports when I/O
  subcells were flattened (#488, devel:Mitch/test_magic_missing_ports has a
  script and expected output;  fixed 8.3.602).  gf180mcuD.
- **[B]** `extract/abstract_stdcells`:  substrate extraction from LEF
  abstract views of standard cells (devel:Anton/bad-extract, fixed 2022).
- **[B]** `extract/drc_then_extract`:  extraction crashed after `drc check`
  with the "full" DRC style left client data on tiles
  (devel:Diarmuid/sunrise).  Check status.
- **[C]** `extract/deterministic`:  the same input should give
  byte-identical .ext and SPICE output (#30, #304, #551;  for extresist
  #538).  Open.  Easy to write:  extract twice and compare.
- **[C]** `extract/pmoscap_length`:  a 12x12 pmoscap extracts with L=6
  (devel:Sylvain/pmoscap, 2026-09).  gf180mcuD.  Open.
- **[C]** `extract/pnp_params`:  PNP M=-nan and wrong area (#246,
  devel:Mitch/bipolar_issue).  Status unclear.
- **[C]** `extract/label_position_cap`:  capacitance of one node depends
  on the position of another node's label (#45).  Status unclear.

### Parasitic R-C extraction (extresist)

These overlap with the current work in `resis/`, so the open items may be
better written as part of that work.

- **[A]** `resis/double_counting`:  resistance double-counted on a wire
  with a third branch (devel:Martin/double_counting, fixed 2025-08).
  sky130A.
- **[A]** `resis/no_substrate_resistor`:  a metal resistor with no
  substrate entry crashed ResReadExt (devel:Torleif/TB_magic_IHP_RM1_ext,
  fixed).  [C] follow-up from the same notes:  `resistor tee` does not
  split the capacitance.  IHP.
- **[A]** `resis/degenerate_triangle`:  #539 (devel:Torleif/
  extresist_alloc_error, fixed 8.3.672).
- **[A]** `resis/residue_recursion`:  #548, a contact whose residue
  includes itself sent FindStartTile into infinite recursion
  (devel:extresist_crash has `magic_bug_repro`, fixed).  sky130A.
- **[A]** `resis/res_ext_path`:  the .res.ext file follows `extract path`
  (devel:Ahmed/rcx, fixed).
- **[A]** `resis/empty_label`:  an empty-string label became a node name
  (devel:Taylor, fixed).  sky130A.
- **[C]** `resis/killed_port`:  extresist killed a port node ("killnode
  VSS"), disconnecting it (devel:extresist_open_net, from netgen #108;
  also devel:Istvan, devel:Leonardo).  Status unclear.
- **[C]** Open extresist and ext2spice issues from GitHub, each with a
  small example:  #550 (coupling capacitance moved to substrate and
  double-counted), #553 (resistor pi model applied to other devices), #556
  (`resistor tee` applies length offsets twice), #559 (coupling caps on
  resistor device terminals), #557 (five defects on ihp-sg13g2, with a
  bench of 63 metal-only layouts:  possibly a source of many tests).

### LEF and DEF

- **[A]** `lef/write_hide_antenna`:  ANTENNAGATEAREA missing with
  `lef write -hide` (devel:Kareem/reproducible, #236;  fixed).  sky130A.
- **[A]** `lef/write_first_call`:  the first `lef write` produced
  incorrect output (SelectRootDef not set;  devel:Sylvain, fixed 2024-03).
- **[A]** `lef/write_hide_obstructions`:  obstructions with `-hide`:  gaps
  between metal stripes (#204, devel:Anton/lef-issue;  OBS_BBOX
  workaround), and nwell (MASTERSLICE) obstruction (#300,
  devel:Sylvain/lef_again).  Confirm which parts are fixed.
- **[C]** `def/special_shield`:  `+ SHIELD <net> <layer> <width> ...` as
  the *first* segment of a special net is not recognized ("Unknown net
  property SHIELD in NET definition"), and the wire is lost:
  "SHIELD" is missing from `net_property_keys` in
  `DefReadNets()` (found while writing `def/read_special_routes`, where
  SHIELD as a later segment works).  Open.
- **[A]** `def/nondefault_rules`:  NONDEFAULTRULE handling in `def read`:
  a net with the rule but no routes passed it to the next net
  (devel:Leo/nondefault_rule, 2026-07, check status);  width not restored
  after a rule (devel:Sylvain/nondefaultrule, fixed);  `def write` wire
  ends offset using the default width (devel:def_write, fixed).  Test
  files in devel:nondefaults.
- **[A]** `def/read_then_gds`:  buffer overflow writing GDS after `def
  read` (file locking state;  #253, devel:Haufe;  fixed).
- **[A]** `lef/read_library`:  smoke test reading the sky130_fd_sc_hd GDS
  and LEF and checking the cells read (VEZZAL cases 1 and 2).
- **[C]** `lef/write_hide_crash`:  `lef write -hide` crash
  (devel:Abhinav, devel:John).  Status unclear.
- **[C]** `def/diearea`:  DIEAREA to FIXED_BBOX on `def read` and back on
  `def write` (devel:Kareem).  Check whether implemented.

### Other sources not yet used

- Closed GitHub issues (140) were not surveyed;  most fixes are also in the
  devel notes above.
- About 35 devel directories have no notes (e.g. Ahmar, Darryl, Jakob,
  snake_res, cell_mgr, flattened_def).  Check them only if needed.
- Netgen tests in VEZZAL (cases 1 to 7) belong in a netgen test suite.

## Done

- `database/instance_position`:  the new `instance position` command
  (8.3.689).
- `database/select_area_labels`:  what each form of `select area`
  selects;  `select area` did not select labels on space (fixed in
  8.3.689).
- `database/splitpaint_box`:  zero-size box and locked layers (#94, #95;
  fails with 8.3.230).
- `database/copy_undo`:  repeated copy and undo (fails with 8.3.522).
- `database/bbox_labels`:  bounding box with label text outside the paint
  (fails with 8.3.545).
- `database/property_scaling`:  FIXED_BBOX and mask hints under
  `scalegrid` and `move origin` (fails with 8.3.517;  also found that
  8.3.688 crashes, fixed in 8.3.689).
- `database/erase_label_corner`:  labels stay attached after erasing part
  of the shape (#305;  fails with 8.3.478 before the fix).
- `database/select_flat_labels`:  label names after `select flat` (fails
  with 8.3.275).
- `database/dup_instance`:  coincident instances with different
  transforms were discarded as duplicates (fails with 8.3.373 from before
  the fix).
- `cif/gds_compressed_ref`:  GDS output when the vendor GDS file has been
  compressed (#366;  fails with 8.3.518).
- `database/exit_code`:  exit status in batch mode (always 0 before
  8.3.447).  The related startup script problem (devel:Aquiles/scripting)
  needs a graphics display and is not tested.
- `def/read_special_routes`:  several routed segments on DEF special nets
  (#264;  fails with 8.3.425).
- `database/split_tile_paint`:  painting over split tiles.  Fails with
  8.3.534 (the August 2025 "stripe" bug) and 8.3.587 (the January 2026
  "corner" bug).
- `cif/gds_aref`:  reading arrays (rotation, single row or column with a
  bogus step, fine pitch).  Fails with 8.3.606 and 8.3.621 (the three
  fixes of February and March 2026).
  `common/gdslib.py` now holds the GDS writer and flattener used by this
  test and `cif/gds_magnification`.
- `database/cell_paths`:  cells shared between directories, saving into
  other directories, and "cd" (GitHub pull request #567).

- `cif/gds_magnification`:  GDS instances with a magnification (including
  non-integer values) were read at the wrong size (Chipalooza slot_4).
- `cif/maxrect_hier`:  "maxrect external" layers were not output correctly
  when the material spans several subcells (IHP sg13cmos5l SEALBOUND).

- `database/long_use_name`:  cell use names over 1024 characters crashed
  "save" and were truncated or unreadable on reading (GitHub issue #564).

- `drc/derived_edge`:  Euclidean corner checks on contact (derived) types,
  for surround and spacing rules (gf180mcuD).
- `drc/halo_rounding`:  DRC halo rounded down, so errors were missed at
  check area boundaries.
- `drc/stdcell_libs`:  DRC of gf180mcuD and sky130A standard cell
  libraries compared with stored results.
