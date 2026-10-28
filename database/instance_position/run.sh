#!/bin/bash
#
# "instance position":  the origin of an instance in its parent cell.  See
# README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.689

cd ${WORK}
echo "" > empty.rc
run_magic -T scmos -rcfile empty.rc ${TESTDIR}/pos.tcl < /dev/null > pos.log
if ! grep -q "^DONE" pos.log; then
    echo "  magic did not finish (see pos.log)"
    finish 1
fi

python3 - <<'PYEOF'
import sys
# Translation (t_c, t_f) of each instance in the saved file
trans = {}
use = None
for line in open('top.mag'):
    f = line.split()
    if f and f[0] == 'use':
        use = f[2]
    elif f and f[0] == 'transform' and use:
        trans[use] = (int(f[3]), int(f[6]))
        use = None

res = {}
for line in open('pos.txt'):
    key, rest = line.split(' ', 1)
    if key in ('name', 'element'):
        name, rest = rest.split(' ', 1)
        key = name
    res[key] = rest.strip()

status = 0
def check(what, got, want):
    global status
    ok = (got == want)
    print('  %-22s %s' % (what, 'ok (%s)' % got if ok else
          '"%s", expected "%s"' % (got, want)))
    if not ok:
        status = 1

for i in range(6):
    u = 'sub_%d' % i
    check(u, res.get(u), '%d %d' % trans[u])
check('one selected', res.get('selected1'), '%d %d' % trans['sub_1'])
# Array sub_5:  element [y][x] is at the first element's position plus
# x * 100 (column pitch) and y * 30 (row pitch)
x0, y0 = trans['sub_5']
for (y, x) in ((0, 0), (0, 2), (1, 1)):
    e = 'sub_5[%d][%d]' % (y, x)
    check(e, res.get(e), '%d %d' % (x0 + 100 * x, y0 + 30 * y))
check('selected sub_5[1][2]', res.get('selectedelement'),
      '%d %d' % (x0 + 200, y0 + 30))
want = ' '.join(sorted('{%d %d}' % trans['sub_%d' % i] for i in range(6)))
check('all selected', res.get('selectedall'), want)
lx, ly = map(float, res['lambda'].split())
ix, iy = map(float, res['internal'].split())
check('units (internal = 2 x lambda)', '%g %g' % (ix, iy), '%g %g' % (2 * lx, 2 * ly))
sys.exit(status)
PYEOF
finish $?
