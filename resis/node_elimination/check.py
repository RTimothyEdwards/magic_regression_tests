import sys, re
# Structural checks on the resistor network in a .res.ext file:
#   check.py <file> <max internal nodes> <prune tolerance or 0>
# Prints the number of resistors on the first line, then any problems.
f, maxint, tol = sys.argv[1], int(sys.argv[2]), float(sys.argv[3])
nodes, res = set(), []
for line in open(f):
    w = line.split()
    if w and w[0] == 'rnode':
        nodes.add(w[1].strip('"'))
    elif w and w[0] == 'resist':
        res.append((w[1].strip('"'), w[2].strip('"'), float(w[3])))
print(len(res))
internal = [n for n in nodes if re.search(r'\.n\d+$', n)]
if len(internal) > maxint:
    print("%d internal nodes (expected at most %d)" % (len(internal), maxint))
for p in ['P%d' % k for k in range(8)] + ['S']:
    if p not in nodes:
        print("port %s missing" % p)
# One connected network
parent = {n: n for n in nodes}
def find(n):
    while parent[n] != n:
        n = parent[n]
    return n
for a, b, r in res:
    parent[find(a)] = find(b)
if len({find(n) for n in nodes}) != 1:
    print("network is not connected")
# No resistor with a path of one or two other resistors below tol times its value
if tol > 0:
    adj = {}
    for i, (a, b, r) in enumerate(res):
        adj.setdefault(a, []).append((b, r, i)); adj.setdefault(b, []).append((a, r, i))
    for i, (a, b, r) in enumerate(res):
        best = None
        for c, r1, j in adj[a]:
            if j == i: continue
            if c == b: path = r1
            else:
                p2 = [r2 for d, r2, k in adj[c] if d == b]
                if not p2: continue
                path = r1 + min(p2)
            best = path if best is None else min(best, path)
        if best is not None and best < tol * r:
            print("negligible resistor %s-%s %g (other path %g)" % (a, b, r, best))
