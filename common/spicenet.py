#!/usr/bin/env python3
#
# spicenet.py --- Analyze the resistor network in a SPICE netlist written by
# "ext2spice", independently of how magic divided the net into resistors.
#
# Usage:
#   spicenet.py <file> res <net1> <net2>
#       Print the effective resistance (ohms) between two nets through the
#       resistors ("R" elements) of the netlist, "0" if they are the same
#       node, or "open" if there is no resistor path between them.
#   spicenet.py <file> dangling
#       Print each subcircuit pin that is not connected to any element (one
#       per line), as "<subcircuit> <pin>".
#   spicenet.py <file> resistors
#       Print the number of resistors and the smallest resistor value.
#   spicenet.py <file> pins
#       Print the pins of the last subcircuit, on one line.
#
# Only the netlist is read;  the expected values come from the test.

import sys

def read_lines(path):
    """Read a SPICE file, joining "+" continuation lines and removing
    comments.  Returns a list of token lists."""
    lines = []
    with open(path) as f:
        for raw in f:
            line = raw.rstrip('\n')
            if not line.strip() or line.lstrip().startswith('*'):
                continue
            if line.startswith('+') and lines:
                lines[-1].extend(line[1:].split())
            else:
                lines.append(line.split())
    return lines

def parse_value(tok):
    """Parse a SPICE number with an optional scale suffix."""
    scale = {'t': 1e12, 'g': 1e9, 'meg': 1e6, 'k': 1e3, 'm': 1e-3,
             'u': 1e-6, 'n': 1e-9, 'p': 1e-12, 'f': 1e-15}
    t = tok.lower()
    for suf in ('meg', 't', 'g', 'k', 'm', 'u', 'n', 'p', 'f'):
        if t.endswith(suf):
            try:
                return float(t[:-len(suf)]) * scale[suf]
            except ValueError:
                break
    return float(t)

def parse(path):
    """Return (subckts, elements), where subckts is a list of
    (name, [pins]) and elements is a list of (name, [nodes], value).
    Element nodes are qualified with the subcircuit name."""
    subckts = []
    elements = []
    current = ''
    for toks in read_lines(path):
        key = toks[0].lower()
        if key == '.subckt':
            current = toks[1]
            pins = [t for t in toks[2:] if '=' not in t]
            subckts.append((current, pins))
        elif key == '.ends':
            current = ''
        elif key.startswith('.'):
            continue
        else:
            first = key[0]
            if first in 'rcl':
                nodes = toks[1:3]
                value = None
                if len(toks) > 3:
                    try:
                        value = parse_value(toks[3])
                    except ValueError:
                        value = None
            elif first == 'x':
                nodes = [t for t in toks[1:-1] if '=' not in t]
                value = None
            elif first == 'm':
                nodes = toks[1:5]
                value = None
            else:
                nodes = [t for t in toks[1:] if '=' not in t][:2]
                value = None
            elements.append((toks[0], [(current, n) for n in nodes], value))
    return subckts, elements

def effective_resistance(elements, a, b):
    """Effective resistance between nodes a and b of the network of
    resistors, or None if there is no path."""
    if a == b:
        return 0.0
    adj = {}
    for name, nodes, value in elements:
        if name[0].lower() != 'r' or value is None:
            continue
        n1, n2 = nodes
        if n1 == n2:
            continue
        adj.setdefault(n1, []).append((n2, value))
        adj.setdefault(n2, []).append((n1, value))
    if a not in adj or b not in adj:
        return None
    # Nodes connected to a
    seen = {a}
    stack = [a]
    while stack:
        n = stack.pop()
        for m, _ in adj[n]:
            if m not in seen:
                seen.add(m)
                stack.append(m)
    if b not in seen:
        return None
    # Solve G v = i with b grounded and 1A injected at a (nodal analysis).
    nodes = [n for n in seen if n != b]
    index = {n: k for k, n in enumerate(nodes)}
    size = len(nodes)
    g = [[0.0] * (size + 1) for _ in range(size)]
    for n in nodes:
        k = index[n]
        for m, r in adj[n]:
            if r == 0:
                r = 1e-9
            g[k][k] += 1.0 / r
            if m != b:
                g[k][index[m]] -= 1.0 / r
    g[index[a]][size] = 1.0
    # Gaussian elimination with partial pivoting
    for col in range(size):
        piv = max(range(col, size), key=lambda r: abs(g[r][col]))
        g[col], g[piv] = g[piv], g[col]
        p = g[col][col]
        if p == 0:
            return None
        for r in range(col + 1, size):
            f = g[r][col] / p
            if f:
                for c in range(col, size + 1):
                    g[r][c] -= f * g[col][c]
    v = [0.0] * size
    for r in range(size - 1, -1, -1):
        s = g[r][size] - sum(g[r][c] * v[c] for c in range(r + 1, size))
        v[r] = s / g[r][r]
    return v[index[a]]

def find_subckt(subckts, net):
    """Name of the (last) subcircuit having the pin, or ''."""
    for name, pins in subckts:
        if net in pins:
            return name
    return subckts[-1][0] if subckts else ''

def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__ if __doc__ else 'usage error')
    subckts, elements = parse(sys.argv[1])
    cmd = sys.argv[2]
    if cmd == 'res':
        net1, net2 = sys.argv[3], sys.argv[4]
        sub = find_subckt(subckts, net1)
        r = effective_resistance(elements, (sub, net1), (sub, net2))
        print('open' if r is None else '%.6g' % r)
    elif cmd == 'dangling':
        used = set()
        for _, nodes, _ in elements:
            used.update(nodes)
        for name, pins in subckts:
            for p in pins:
                if (name, p) not in used:
                    print(name, p)
    elif cmd == 'pins':
        print(' '.join(subckts[-1][1]) if subckts else '')
    elif cmd == 'resistors':
        vals = [v for n, _, v in elements if n[0].lower() == 'r' and v is not None]
        print(len(vals), ('%.6g' % min(vals)) if vals else '-')
    else:
        sys.exit('unknown command ' + cmd)

if __name__ == '__main__':
    main()
