#!/bin/bash
#
# DRC of open PDK standard cell libraries, compared against a baseline.
# See README.md.  Run with "UPDATE=1" to regenerate the baseline files.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

status=0
ran=0

for entry in gf180mcuD:gf180mcu_fd_sc_mcu9t5v0 \
	     gf180mcuD:gf180mcu_fd_sc_mcu7t5v0 \
	     sky130A:sky130_fd_sc_hd; do
    pdk=${entry%%:*}
    lib=${entry##*:}
    libdir=${PDK_ROOT}/${pdk}/libs.ref/${lib}/mag
    if [ ! -d ${libdir} ]; then
	echo "  ${lib}: not found, skipped"
	continue
    fi
    ran=$((ran + 1))
    LIBDIR=${libdir} run_magic -rcfile ${PDK_ROOT}/${pdk}/libs.tech/magic/${pdk}.magicrc \
	${TESTDIR}/libcheck.tcl > ${WORK}/${lib}.log
    grep "^ERR " ${WORK}/${lib}.log | sed 's/^ERR //' | sort > ${WORK}/${lib}.txt
    ncells=$(ls ${libdir}/*.mag | wc -l)
    nerr=$(cut -d' ' -f1 ${WORK}/${lib}.txt | sort -u | wc -l)
    expected=${TESTDIR}/expected/${lib}.txt
    if [ -n "${UPDATE}" ]; then
	cp ${WORK}/${lib}.txt ${expected}
	echo "  ${lib}: ${ncells} cells, ${nerr} with errors (baseline updated)"
    elif ! diff ${expected} ${WORK}/${lib}.txt > ${WORK}/${lib}.diff; then
	echo "  ${lib}: ${ncells} cells, ${nerr} with errors, differs from baseline:"
	head -20 ${WORK}/${lib}.diff
	status=1
    else
	echo "  ${lib}: ${ncells} cells, ${nerr} with errors (matches baseline)"
    fi
done

if [ ${ran} -eq 0 ]; then
    echo "SKIP: no libraries found in ${PDK_ROOT}"
    exit 77
fi
finish ${status}
