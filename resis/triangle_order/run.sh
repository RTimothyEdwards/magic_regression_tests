#!/bin/bash
#
# Repeat extresist on a multi-port crossing with a row of vias, changing
# heap allocation before each run.  See README.md.

TESTDIR=$(cd "$(dirname "$0")" && pwd)
source "${TESTDIR}/../../common/common.sh"
require_magic_version 8.3.697

cd "${WORK}"
echo "" > empty.rc
status=0

# With seven contacts, the shared metal1 node has nine connections.
# Eight contacts reach the ten-connection hash path; twelve give several
# possible triangle conversions.  Zero contacts leave two separate wires.
for contacts in 0 7 8 12; do
    different=0
    valid=0
    reference=""
    for run in {0..15}; do
        name=c${contacts}_${run}
        mkdir "${name}"
        if ! (cd "${name}" &&
            CONTACTS=${contacts} HEAP_PAD_BYTES=$((run * 4093)) \
                run_magic -T scmos -rcfile "${WORK}/empty.rc" \
                "${TESTDIR}/layout.tcl" < /dev/null > magic.log); then
            echo "  ${name}:  magic failed (see magic.log)"
            status=1
            continue
        fi
        if ! grep -q '^DONE$' "${name}/magic.log"; then
            echo "  ${name}:  magic did not finish (see magic.log)"
            status=1
            continue
        fi
        if ! python3 "${TESTDIR}/check.py" "${name}/top.res.ext" \
                "${contacts}" > "${name}/network" 2> "${name}/check.log"; then
            echo "  ${name}:  invalid network (see check.log)"
            status=1
            continue
        fi
        if [ -z "${reference}" ]; then
            reference="${name}/network"
        elif ! cmp -s "${reference}" "${name}/network"; then
            different=$((different + 1))
            status=1
        fi
        valid=$((valid + 1))
    done
    if [ ${valid} -ne 16 ]; then
        echo "  ${contacts} contacts:  FAIL: only ${valid} valid outputs, expected 16"
        status=1
    elif [ ${different} -gt 0 ]; then
        echo "  ${contacts} contacts:  FAIL: ${different} runs differ from the first network"
    else
        echo "  ${contacts} contacts:  same network in all 16 runs"
    fi
done

finish ${status}
