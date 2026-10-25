#!/bin/bash
#
# common.sh --- Shared setup for magic regression test scripts.
# Source this file from a test's run.sh after setting TESTDIR.
#
# Environment variables (all optional):
#
#   MAGIC      Command used to run magic.  Default "magic".  To test a
#              build staged with "make install DESTDIR=<dir>", use e.g.
#              MAGIC="env CAD_ROOT=<dir>/usr/local/lib bash <dir>/usr/local/bin/magic"
#   PDK_ROOT   Location of installed open PDKs.  Default /usr/share/pdk.
#   KEEPWORK   If set, do not delete the test's work/ directory on success.

: ${PDK_ROOT:=/usr/share/pdk}
: ${MAGIC:=magic}

WORK=${TESTDIR}/work
rm -rf ${WORK}
mkdir -p ${WORK}

# Run magic in batch mode with the given arguments.  All output goes to
# stdout so that it can be filtered or saved to a log.

run_magic() {
    ${MAGIC} -dnull -noconsole "$@" 2>&1
}

# Check that a PDK exists, or else skip the test (exit code 77).

require_pdk() {
    if [ ! -d ${PDK_ROOT}/$1 ]; then
	echo "SKIP: PDK $1 not found in ${PDK_ROOT}"
	exit 77
    fi
}

# single_rule_tech <source tech> <output tech> <drc section body>
#
# Copy a tech file, replacing the entire contents of its "drc" section
# with the given text.  This is used to test one rule in isolation, since
# in a full rule deck, overlapping rules can mask each other (only one
# reason is reported for an error area).

single_rule_tech() {
    awk -v body="$3" '
	state == 0 && /^drc[ \t]*$/ { print; print body; state = 1; next }
	state == 1 && /^end[ \t]*$/ { print; state = 2; next }
	state == 1 { next }
	{ print }
    ' $1 > $2
}

# Finish a test:  print PASS or FAIL and exit with status 0 or 1.
# Remove the work directory on success unless KEEPWORK is set.

finish() {
    if [ "$1" = "0" ]; then
	echo "PASS: $(basename ${TESTDIR})"
	[ -z "${KEEPWORK}" ] && rm -rf ${WORK}
	exit 0
    else
	echo "FAIL: $(basename ${TESTDIR}) (see ${WORK})"
	exit 1
    fi
}
