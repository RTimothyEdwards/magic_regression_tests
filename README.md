# Magic regression tests

Examples and regression tests for the [magic](https://github.com/RTimothyEdwards/magic)
VLSI layout editor.  These are kept separate from the magic source
repository because there are far too many cases worth checking to keep
them with the source.

## Running the tests

```
./run_tests.sh              # run all tests
./run_tests.sh drc          # run all tests under drc/
./drc/derived_edge/run.sh   # run one test
```

Each test prints a summary of what it checked and ends with a line
`PASS: <name>`, `FAIL: <name>`, or `SKIP: <reason>`.  `run_tests.sh`
prints a count of each at the end and exits non-zero if any test failed.

Environment variables:

| Variable   | Default         | Meaning |
|------------|-----------------|---------|
| `MAGIC`    | `magic`         | Command used to run magic |
| `PDK_ROOT` | `/usr/share/pdk`| Location of the installed open PDKs |
| `KEEPWORK` | (unset)         | Keep each test's `work/` directory even if the test passes |
| `VALGRIND` | (unset)         | Run magic under valgrind;  a test also fails if valgrind reports memory errors (reports are kept in `work/`).  Much slower:  for occasional runs. |

To test a build of magic without installing it over an existing
installation, configure it with `./configure --prefix=<dir>`, then `make`
and `make install`, and run:

```
MAGIC=<dir>/bin/magic ./run_tests.sh
```

(Staging with `make install DESTDIR=<dir>` and running it with
`CAD_ROOT=<dir>/usr/local/lib` does not always work:  older versions of
magic then load the copy of magic installed in /usr/local instead.  The
"revision" line at the start of a test's log shows which version ran.)

Most tests use the open PDKs (gf180mcuD, sky130A) as installed by
[open_pdks](https://github.com/RTimothyEdwards/open_pdks).  A test whose
PDK is not installed is skipped.

## Automatic runs on GitHub

The tests are run on GitHub by the workflows in `.github/workflows/`:

- `regression.yml` builds magic and runs all of the tests.  It is a
  reusable workflow, called by:
  - the magic repository's `.github/workflows/regression.yml`, for every
    pull request to magic, so the result appears as a check on the pull
    request;
  - `nightly.yml` in this repository, which tests the magic `master` branch
    every night, whenever the tests change, and on request (from the
    "Actions" tab, "Run workflow").
- The PDKs are installed with [ciel](https://github.com/fossi-foundation/ciel)
  at the fixed versions listed in `pdk_versions`, so that the results depend
  on the version of magic and not on the version of the PDK.  To use the
  same PDKs locally, run `ci/install_pdks.sh <pdk_root>` and set `PDK_ROOT`.
- If any test fails, the `work/` directories of the failed tests are saved
  as a downloadable artifact of the workflow run.

## Layout

```
run_tests.sh          Runs all tests (any directory containing run.sh)
common/common.sh      Shared setup and helper functions for run.sh scripts
cif/                  CIF/GDS input and output tests
    gds_aref/         GDS arrays with rotation and a single row or column
    gds_compressed_ref/  GDS output when the vendor GDS file is compressed
    gds_magnification/  GDS instances with magnification
    maxrect_hier/     Hierarchical output of "maxrect external" layers
database/             Database, editing, and command tests
    bbox_labels/      Cell bounding box with label text outside the paint
    cell_paths/       Cell file paths for cells shared between directories
    copy_undo/        Repeated "copy" of a cell instance followed by "undo"
    dup_instance/     Coincident cell instances with different transforms
    erase_label_corner/  Labels stay attached when part of the shape is erased
    exit_code/        Exit status of magic in batch mode
    instance_position/  The "instance position" command
    long_use_name/    Cell use names longer than the read and write buffers
    property_scaling/ FIXED_BBOX and mask hints under scalegrid and move origin
    select_area_labels/  What "select area" selects (paint, labels, instances)
    select_flat_labels/  Label names after "select flat"
    split_tile_paint/ Painting over split (non-Manhattan) tiles
    splitpaint_box/   "splitpaint" with a zero-size box or a locked layer
def/                  LEF and DEF tests
    read_special_routes/  DEF special nets with several routed segments
drc/                  DRC tests
    derived_edge/     Euclidean corner checks on contact (derived) types
    halo_rounding/    Errors at DRC check area boundaries
    stdcell_libs/     DRC of standard cell libraries against a baseline
```

## Writing a test

A test is a directory containing an executable `run.sh` and whatever
scripts, layout, and expected results it needs, plus a `README.md` saying
what the test checks and why.  `run.sh` should:

- set `TESTDIR` to its own directory and source `common/common.sh`;
- put all generated files in `${WORK}` (the test's `work/` directory,
  which is created fresh on each run and is not checked in);
- call `require_pdk <name>` for each PDK it needs;
- if the test goes with a fix to magic, call `require_magic_version
  <version>` with the first magic version that has the fix (the version in
  magic's VERSION file after the fix), so that the test is skipped rather
  than failing with an older magic.  A test pushed together with a fix
  would otherwise fail on GitHub until the magic repository is mirrored
  there overnight;
- end with `finish <status>`, where status 0 means pass.

`common.sh` also provides `run_magic` (runs `${MAGIC}` in batch mode) and
`single_rule_tech` (copies a tech file with its DRC section replaced, for
testing one rule in isolation).

Where possible, a test should compute the correct answer independently
of magic, rather than comparing against magic's own earlier output, and
should report both false positives and false negatives.
