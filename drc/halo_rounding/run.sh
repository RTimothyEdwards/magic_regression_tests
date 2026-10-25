#!/bin/bash
#
# DRC halo rounding.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk gf180mcuD

TECH=${PDK_ROOT}/gf180mcuD/libs.tech/magic/gf180mcuD.tech

# The only rule is 240 at scalefactor 50 (4.8 lambda), so the DRC halo is
# set by this rule.  The halo must round up to 5 lambda, not down to 4.
single_rule_tech ${TECH} ${WORK}/pcpc.tech \
	"$(printf ' style drc\n scalefactor 50\n cifstyle drc\n spacing pc pc 240 touching_ok "PCPC"')"
printf 'drc euclidean on\nscalegrid 1 10\n' > ${WORK}/halo.rc

run_magic -T ${WORK}/pcpc.tech -rcfile ${WORK}/halo.rc ${TESTDIR}/halo.tcl \
	> ${WORK}/halo.log
grep "^RESULT" ${WORK}/halo.log || { finish 1; }
grep "missed error" ${WORK}/halo.log | head -10
grep -q "^RESULT.* missed=0$" ${WORK}/halo.log
finish $?
