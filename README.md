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

To test a build of magic without installing it over an existing
installation, stage it with `make install DESTDIR=<dir>` and run:

```
MAGIC="env CAD_ROOT=<dir>/usr/local/lib bash <dir>/usr/local/bin/magic" ./run_tests.sh
```

Most tests use the open PDKs (gf180mcuD, sky130A) as installed by
[open_pdks](https://github.com/RTimothyEdwards/open_pdks).  A test whose
PDK is not installed is skipped.

## Layout

```
run_tests.sh          Runs all tests (any directory containing run.sh)
common/common.sh      Shared setup and helper functions for run.sh scripts
cif/                  CIF/GDS output tests
    maxrect_hier/     Hierarchical output of "maxrect external" layers
database/             Database (.mag file) tests
    cell_paths/       Cell file paths for cells shared between directories
    long_use_name/    Cell use names longer than the read and write buffers
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
- end with `finish <status>`, where status 0 means pass.

`common.sh` also provides `run_magic` (runs `${MAGIC}` in batch mode) and
`single_rule_tech` (copies a tech file with its DRC section replaced, for
testing one rule in isolation).

Where possible, a test should compute the correct answer independently
of magic, rather than comparing against magic's own earlier output, and
should report both false positives and false negatives.
