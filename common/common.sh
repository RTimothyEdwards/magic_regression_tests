#!/bin/bash
#
# common.sh --- Shared setup for magic regression test scripts.
# Source this file from a test's run.sh after setting TESTDIR.
#
# Environment variables (all optional):
#
#   MAGIC      Command used to run magic.  Default "magic".  To test a
#              build installed with "./configure --prefix=<dir>", use
#              MAGIC=<dir>/bin/magic.  (A build staged with "make install
#              DESTDIR=<dir>" and run with CAD_ROOT=<dir>/usr/local/lib
#              may silently run the copy of magic installed in /usr/local
#              instead;  check the "revision" line in the test's log.)
#   PDK_ROOT   Location of installed open PDKs.  Default /usr/share/pdk.
#   KEEPWORK   If set, do not delete the test's work/ directory on success.
#   VALGRIND   If set, run magic under valgrind (much slower).  A test then
#              also fails if valgrind reports any memory errors;  the
#              reports are kept in the test's work/ directory as
#              valgrind.<pid>.log.

: ${PDK_ROOT:=/usr/share/pdk}
: ${MAGIC:=magic}

WORK=${TESTDIR}/work
rm -rf ${WORK}
mkdir -p ${WORK}

# Run magic in batch mode with the given arguments.  All output goes to
# stdout so that it can be filtered or saved to a log.  The exit status is
# magic's own (also under valgrind, whose reports are checked by finish()).

run_magic() {
    if [ -n "${VALGRIND}" ]; then
	# The magic command is normally a shell script, so follow it into
	# the programs it runs.
	valgrind --trace-children=yes --num-callers=30 \
		--log-file=${WORK}/valgrind.%p.log \
		${MAGIC} -dnull -noconsole "$@" 2>&1
    else
	${MAGIC} -dnull -noconsole "$@" 2>&1
    fi
}

# Under VALGRIND, check the valgrind reports in ${WORK}:  print a summary
# of any that found errors.  Returns 1 if any did, 0 otherwise.

check_valgrind() {
    local f bad=0
    [ -z "${VALGRIND}" ] && return 0
    for f in ${WORK}/valgrind.*.log; do
	[ -f "${f}" ] || continue
	if grep -q "ERROR SUMMARY: [1-9]" ${f}; then
	    echo "  valgrind:  $(grep -o 'ERROR SUMMARY: [0-9]* errors' ${f}) in $(basename ${f})"
	    # The first error and where it happened
	    grep -m1 -A4 "^==[0-9]*== [A-Z].*\(Invalid\|uninitialised\|Mismatched\|overlap\|Syscall\)" ${f} |
		    sed 's/^==[0-9]*== /    /'
	    bad=1
	fi
    done
    return ${bad}
}

# Check that a PDK exists, or else skip the test (exit code 77).

require_pdk() {
    if [ ! -d ${PDK_ROOT}/$1 ]; then
	echo "SKIP: PDK $1 not found in ${PDK_ROOT}"
	exit 77
    fi
}

# Skip the test (exit code 77) if magic is older than the given version
# (e.g. "require_magic_version 8.3.688").  Use this in a test that goes
# with a fix to magic, giving the first version that has the fix, so that
# the test is skipped instead of failing when run with an older magic (for
# example, on GitHub before the magic repository has been mirrored).

require_magic_version() {
    local have
    have=$(${MAGIC} --version 2>/dev/null | tail -n 1)
    if [ -z "${have}" ]; then
	echo "  (could not get the magic version;  running the test anyway)"
	return
    fi
    if [ "$(printf '%s\n%s\n' "$1" "${have}" | sort -V | head -n 1)" != "$1" ]; then
	echo "SKIP: $(basename ${TESTDIR}) needs magic $1 (this is ${have})"
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
    if [ "$1" = "0" ] && ! check_valgrind; then
	set -- 1
    elif [ "$1" != "0" ]; then
	check_valgrind
    fi
    if [ "$1" = "0" ]; then
	echo "PASS: $(basename ${TESTDIR})"
	[ -z "${KEEPWORK}" ] && rm -rf ${WORK}
	exit 0
    else
	echo "FAIL: $(basename ${TESTDIR}) (see ${WORK})"
	exit 1
    fi
}
