#!/usr/bin/env python3
# Check seven independent metal resistors, including coincident locations.
from pathlib import Path
import math
import shlex
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "common"))
from spicenet import effective_resistance, parse


def transform(x, y, orientation):
    return {"r0": (x, y), "r90": (-y, x), "r180": (-x, -y),
            "r270": (y, -x), "mx": (x, -y), "my": (-x, y)}[orientation]


def layout(stacked, orientation):
    lines = ["crashbackups stop", "drc off", "load collision"]

    def box(x0, y0, x1, y1):
        points = [transform(x, y, orientation) for x, y in [(x0, y0), (x1, y1)]]
        xs, ys = zip(*points)
        lines.append("box values %gum %gum %gum %gum" %
                     (min(xs), min(ys), max(xs), max(ys)))

    for index in range(1, 8):
        x = 0 if stacked else (index - 1) * 5
        box(x, 0, x + 2, 30)
        lines.append("paint m%d" % index)
        box(x, 12, x + 2, 18)
        lines.append("paint rm%d" % index)
        for port, y in [("P1", 0), ("P2", 28)]:
            box(x, y, x + 2, y + 2)
            lines.extend(["label %s_M%d c m%d" % (port, index, index), "port make"])
    lines.extend(["save collision", "extresist minres 0", "extresist mindelay 0",
                  "extresist threshold 0", "extract do resistance", "extract all",
                  "ext2spice lvs", "ext2spice cthresh 0", "ext2spice extresist on",
                  "ext2spice -o collision.spice", "puts SHARED_RESISTORS_DONE",
                  "quit -noprompt"])
    return "\n".join(lines) + "\n"


def check_case(magic, rc, directory, stacked, orientation):
    directory.mkdir()
    (directory / "layout.tcl").write_text(layout(stacked, orientation), encoding="utf-8")
    with (directory / "magic.log").open("w", encoding="utf-8") as output:
        process = subprocess.run(shlex.split(magic) + ["-dnull", "-noconsole", "-rcfile", str(rc),
                                  "layout.tcl"], cwd=directory, stdin=subprocess.DEVNULL,
                                 stdout=output, stderr=subprocess.STDOUT, timeout=60)
    log = (directory / "magic.log").read_text(encoding="utf-8", errors="replace")
    if process.returncode or "SHARED_RESISTORS_DONE" not in log:
        raise ValueError("extraction did not finish; see magic.log")
    if any(text in log for text in ["No device of type", "Error in extracting node",
                                    "Orphaned node", "Couldn't find device"]):
        raise ValueError("device extraction errors; see magic.log")

    devices = [shlex.split(line) for line in (directory / "collision.ext").read_text(
        encoding="utf-8").splitlines() if line.startswith("device ")]
    if len(devices) != 7 or any(row[1:3] != ["devres", "None"] for row in devices):
        raise ValueError("expected seven original metal resistors sharing model None")
    expected_body = {}
    for row in devices:
        port_names = [word for word in row if word.startswith(("P1_M", "P2_M"))]
        if len(port_names) != 2:
            raise ValueError("unexpected original resistor terminals")
        expected_body[frozenset(port_names)] = float(row[7])

    subckts, elements = parse(str(directory / "collision.spice"))
    if len(subckts) != 1:
        raise ValueError("expected one top subcircuit")
    top, pins = subckts[0]
    ports = [(top, name) for index in range(1, 8)
             for name in ["P1_M" + str(index), "P2_M" + str(index)]]
    if set(pins) != {node[1] for node in ports}:
        raise ValueError("missing or unexpected external ports")
    resistors = [(name, nodes, value) for name, nodes, value in elements
                 if name[0].lower() == "r"]
    if any(value is None or not math.isfinite(value) or value < 0
           for _, _, value in resistors):
        raise ValueError("invalid resistance")

    parent = {}
    def find(node):
        parent.setdefault(node, node)
        if parent[node] != node:
            parent[node] = find(parent[node])
        return parent[node]
    for _, nodes, _ in resistors:
        parent[find(nodes[0])] = find(nodes[1])
    for index in range(1, 8):
        a, b = (top, "P1_M" + str(index)), (top, "P2_M" + str(index))
        connected_ports = {port for port in ports if find(port) == find(a)}
        if connected_ports != {a, b}:
            raise ValueError("M%d is open or shorted to another layer" % index)
        for port in [a, b]:
            if not any(port in nodes and any(n not in ports for n in nodes) and value > 0
                       for _, nodes, value in resistors):
                raise ValueError("%s lacks an extracted lead" % port[1])
        got = effective_resistance(elements, a, b)
        # Port centers are 28um apart; the resistor body is 6um long.
        expected = expected_body[frozenset([a[1], b[1]])] * 28 / 6
        # Allow writer rounding and small terminal-connection resistances.
        if got is None or abs(got - expected) > max(0.002, expected * 0.005):
            raise ValueError("M%d resistance %s, expected about %.6g ohm" %
                             (index, got, expected))


magic, pdk_root, work = sys.argv[1:4]
work = Path(work)
rc = Path(pdk_root) / "ihp-sg13g2/libs.tech/magic/ihp-sg13g2.magicrc"
status = 0
for stacked in [False, True]:
    for orientation in ["r0", "r90", "r180", "r270", "mx", "my"]:
        name = ("stacked" if stacked else "separated") + "_" + orientation
        try:
            check_case(magic, rc, work / name, stacked, orientation)
            print("  %-16s ok: seven independent paths and fourteen leads" % name, flush=True)
        except (ValueError, OSError, subprocess.TimeoutExpired) as error:
            print("  %-16s FAIL: %s" % (name, error), flush=True)
            status = 1
sys.exit(status)
