#!/bin/bash
#
# The output of "extresist" must not depend on the order of records in the
# .ext file.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.695

RC=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc
status=0
cd ${WORK}

# run_case <cell> <name> <seed> <kinds...>:  write the shuffled .ext file in
# directory <cell>_<name> and run extresist on it.  Seed 0 keeps the original
# order.
run_case() {
    local cell=$1 dir=$1_$2 seed=$3; shift 3
    mkdir -p ${dir}
    cp ${cell}/${cell}.mag ${dir}/
    if [ ${seed} == 0 ]; then
	cp ${cell}/${cell}.ext ${dir}/
    else
	python3 ${TESTDIR}/shuffle.py ${cell}/${cell}.ext ${dir}/${cell}.ext \
	    ${seed} "$@"
    fi
    (cd ${dir} && CASE=${cell} run_magic -rcfile ${RC} \
	${TESTDIR}/extresist.tcl > extresist.log)
}

for cell in drivers mux4; do
    mkdir -p ${cell}
    (cd ${cell} && CASE=${cell} run_magic -rcfile ${RC} ${TESTDIR}/layout.tcl \
	> layout.log)
    run_case ${cell} 0 0
    python3 ${TESTDIR}/normalize.py ${cell}_0/${cell}.res.ext > ${cell}_0.norm

    # Coupling capacitor records are the ones known to change order between
    # runs of "extract", so a new order of those alone must not change the
    # file at all.  A new order of any records must not change the networks.
    # Seed -1 reverses the order.
    for seed in -1 1 2 3; do
	run_case ${cell} c${seed} ${seed} cap
	if cmp -s ${cell}_0/${cell}.res.ext ${cell}_c${seed}/${cell}.res.ext
	then
	    result="ok:  same file"
	else
	    result="FAIL:  file differs, see ${cell}_c${seed}"
	    status=1
	fi
	printf '  %-16s %s\n' "${cell}, caps ${seed}:" "${result}"

	run_case ${cell} a${seed} ${seed} port node cap device
	python3 ${TESTDIR}/normalize.py ${cell}_a${seed}/${cell}.res.ext \
	    > ${cell}_a${seed}.norm
	if [ ! -s ${cell}_0.norm ]; then
	    result="FAIL:  no output, see ${cell}_0"
	    status=1
	elif cmp -s ${cell}_0.norm ${cell}_a${seed}.norm; then
	    result="ok:  same networks"
	else
	    result="FAIL:  networks differ, see ${cell}_a${seed}"
	    status=1
	fi
	printf '  %-16s %s\n' "${cell}, all ${seed}:" "${result}"
    done
done

finish ${status}
