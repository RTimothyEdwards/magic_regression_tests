#!/bin/bash
#
# File locking when reading cells:  locks held by another magic process,
# "locking disable", and files without write permission.  See README.md.

TESTDIR=$(cd "$(dirname "$0")" && pwd)
source "${TESTDIR}/../../common/common.sh"
require_magic_version 8.3.705

cd "${WORK}"
status=0
MAGICARGS="-rcfile /dev/null -T scmos"

# reader <name> <enable|disable> <expected states for top c0 c1 c2>
#
# Run reader.tcl and compare the cell states.  The log is left in
# <name>.log for the message checks.

reader() {
    local name=$1 locking=$2 expected states
    shift 2
    expected="$*"
    LOCKING=${locking} WRITECELL=${WRITECELL:-top} run_magic ${MAGICARGS} "${TESTDIR}/reader.tcl" \
	    < /dev/null > ${name}.log
    if ! grep -q '^READER_DONE' ${name}.log; then
	echo "  ${name}:  FAIL: magic did not finish (see ${name}.log)"
	status=1
	return
    fi
    states=$(awk '/^STATE / { printf "%s%s", sep, $3; sep = " " }' ${name}.log)
    if [ "${states}" != "${expected}" ]; then
	echo "  ${name}:  FAIL: top c0 c1 c2 are \"${states}\", expected \"${expected}\""
	status=1
    else
	echo "  ${name}:  ${states}"
    fi
}

# expect_message <name> <yes|no> <pattern> <description>

expect_message() {
    if grep -q "$3" $1.log; then
	found=yes
    else
	found=no
    fi
    if [ ${found} != $2 ]; then
	echo "  $1:  FAIL: message \"$4\" found=${found}, expected $2"
	status=1
    fi
}

run_magic ${MAGICARGS} "${TESTDIR}/layout.tcl" < /dev/null > layout.log
if ! grep -q '^LAYOUT_DONE' layout.log; then
    echo "  FAIL: could not make the layout (see layout.log)"
    finish 1
fi

# Locking is enabled by default, and no other process holds a lock.

reader unlocked enable writeable writeable writeable writeable
if ! grep -q '^LOCKING enabled' unlocked.log; then
    echo "  unlocked:  FAIL: locking is not enabled by default"
    status=1
fi
expect_message unlocked no "already locked" "already locked"

# Another magic process holds locks on all four files.

rm -f ready release
LOCKING=enable run_magic ${MAGICARGS} "${TESTDIR}/holder.tcl" \
	< /dev/null > holder.log &
holder=$!
for i in $(seq 600); do
    [ -f ready ] && break
    kill -0 ${holder} 2> /dev/null || break
    sleep 0.1
done
if [ ! -f ready ]; then
    echo "  FAIL: holding process did not start (see holder.log)"
    kill ${holder} 2> /dev/null
    finish 1
fi

reader locked enable read-only read-only read-only read-only
expect_message locked yes "already locked" "already locked"
expect_message locked yes "advisory lock is held" "advisory lock is held"

# With locking disabled, the locks of the other process are ignored.

reader disabled disable writeable writeable writeable writeable
expect_message disabled no "already locked" "already locked"
if ! grep -q '^LOCKING disabled' disabled.log; then
    echo "  disabled:  FAIL: \"locking disable\" did not disable locking"
    status=1
fi

touch release
wait ${holder}
if ! grep -q '^HOLDER_DONE' holder.log; then
    echo "  FAIL: holding process did not finish (see holder.log)"
    status=1
fi

# The locks are released when the other process exits.

reader released enable writeable writeable writeable writeable

# A file without write permission is read-only, whether or not locking
# is enabled, and is reported as not writeable, not as locked.  (Not
# checked when running as root, which can write it.)

chmod a-w c1.mag
if [ -w c1.mag ]; then
    echo "  no_write:  skipped (running as root)"
else
    for locking in enable disable; do
	WRITECELL=c1 reader no_write_${locking} ${locking} \
		writeable writeable read-only writeable
	expect_message no_write_${locking} yes "^Warning: cell <c1> from file .* is not writeable" \
		"not writeable"
	expect_message no_write_${locking} no "locked" "already locked"
	expect_message no_write_${locking} no "advisory lock is held" \
		"advisory lock is held"
    done
fi
chmod u+w c1.mag

finish ${status}
