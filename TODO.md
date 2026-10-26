# To do

## Next step:  survey past issues for test cases

Go through the places where past issues have been described and write
down a list of regression tests to implement.  For each one, record:

- what to test (command, subsystem, expected behavior);
- where the information and example files are (directory, issue or PR
  number);
- whether the issue is fixed (a test should pass) or still open (a test
  would document the bug);
- which PDK or tech file it needs.

Put the list below, under "Tests to implement", and work through it.

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

## Tests to implement

(To be filled in by the survey above.)

## Done

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
