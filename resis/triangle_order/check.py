#!/usr/bin/env python3
#
# Check that extraction produced a connected, nonempty resistor network,
# then print normalized records for repeatability comparisons.  Ignore
# record order and the direction in which a resistor was written.

import math
from pathlib import Path
import shlex
import sys


def normalize(path, contacts):
    records = [shlex.split(line) for line in path.read_text().splitlines() if line.strip()]
    nodes = {record[1] for record in records if record[0] == "rnode"}
    ports = {"A", "B", "C", "D"}
    if not ports <= nodes:
        raise ValueError(f"missing ports: {sorted(ports - nodes)}")
    graph = {node: set() for node in nodes}
    resistors = 0
    for record in records:
        if record[0] != "resist":
            continue
        if len(record) != 4:
            raise ValueError(f"invalid resistor: {record}")
        _, a, b, text = record
        value = float(text)
        if not math.isfinite(value) or value <= 0 or a == b:
            raise ValueError(f"invalid resistor: {record}")
        if a not in graph or b not in graph:
            raise ValueError(f"undeclared resistor endpoint: {record}")
        graph[a].add(b)
        graph[b].add(a)
        record[1:3] = sorted((a, b))
        resistors += 1
    if resistors < 2:
        raise ValueError(f"expected a resistor network, found {resistors} resistors")

    components = set()
    remaining = set(nodes)
    while remaining:
        pending = [next(iter(remaining))]
        component = set()
        while pending:
            node = pending.pop()
            if node in component:
                continue
            component.add(node)
            pending.extend(graph[node] - component)
        if not component & ports:
            raise ValueError(f"internal component without a port: {sorted(component)}")
        components.add(frozenset(component & ports))
        remaining -= component
    expected = {frozenset(ports)} if contacts else {frozenset("AB"), frozenset("CD")}
    if components != expected:
        raise ValueError(f"wrong port connectivity: {components}, expected {expected}")

    return "\n".join(sorted(" ".join(record) for record in records))


if __name__ == "__main__":
    try:
        print(normalize(Path(sys.argv[1]), int(sys.argv[2])))
    except (OSError, ValueError, IndexError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
