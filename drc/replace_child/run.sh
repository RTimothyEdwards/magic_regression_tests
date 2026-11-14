#!/bin/bash
#
# A parent cell must be checked after a child that is put on the DRC
# pending list later.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.702

cd ${WORK}
echo "" > empty.rc
run_magic -T scmos -rcfile empty.rc ${TESTDIR}/replace.tcl < /dev/null > replace.log
before=$(grep "^COUNT before" replace.log | cut -d' ' -f3)
after=$(grep "^COUNT after" replace.log | cut -d' ' -f3-)
recheck=$(grep "^COUNT recheck" replace.log | cut -d' ' -f3-)
status=0
if [ "${before}" != "0" ]; then
    echo "  clean instance:  ${before} errors in top, expected 0"
    status=1
elif [ -z "${after}" ] || [ "${after}" != "${recheck}" ]; then
    echo "  after replacement:  \"${after}\" (top, all), expected \"${recheck}\" as after a full recheck"
    status=1
elif [ "${after%% *}" = "0" ]; then
    echo "  after replacement:  no errors in top"
    status=1
else
    echo "  errors (top, all) after replacing the instance:  ${after}:  ok"
fi
finish ${status}
