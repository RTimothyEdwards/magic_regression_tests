#!/usr/bin/env python3
# Compare both native and SPICE capacitance with the technology's area rule.
from pathlib import Path
import math
import os
import shlex
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "common"))
from spicenet import parse

magic, pdk_root, work, tech = sys.argv[1:5]
work = Path(work)
rc = Path(pdk_root) / "sky130A/libs.tech/magic/sky130A.magicrc"
coefficient = None
inside = False
for line in Path(tech).read_text(encoding="utf-8").splitlines():
    words = line.split()
    if words and words[0] == "extract":
        inside = True
    if inside and len(words) >= 6 and words[0] == "defaultoverlap" and \
            words[2] == "metal2" and words[4] == "metal1":
        coefficient = float(words[5])
        break
if coefficient is None or not math.isfinite(coefficient) or coefficient <= 0:
    print("  FAIL: missing nominal metal2-to-metal1 overlap coefficient")
    sys.exit(1)

status = 0
for side in [20, 100, 200, 231.70, 231.71, 300, 450, 1000]:
    name = "plate_" + str(side).replace(".", "p")
    directory = work / name
    directory.mkdir()
    environment = dict(os.environ, SIDE_UM=str(side))
    try:
        with (directory / "magic.log").open("w", encoding="utf-8") as output:
            process = subprocess.run([magic, "-dnull", "-noconsole", "-rcfile", str(rc),
                                      str(Path(__file__).with_name("plate.tcl"))],
                                     cwd=directory, env=environment, stdin=subprocess.DEVNULL,
                                     stdout=output, stderr=subprocess.STDOUT, timeout=60)
        log = (directory / "magic.log").read_text(encoding="utf-8", errors="replace")
        if process.returncode or "LARGE_OVERLAP_DONE" not in log:
            raise ValueError("extraction did not finish; see magic.log")
        scale = None
        native = 0.0
        for line in (directory / "plate.ext").read_text(encoding="utf-8").splitlines():
            row = shlex.split(line)
            if row and row[0] == "scale":
                scale = float(row[2])
            if row and row[0] == "cap" and set(row[1:3]) == {"a", "b"}:
                native += float(row[3])
        if scale is None or not math.isfinite(scale) or scale <= 0:
            raise ValueError("invalid native capacitance scale")
        native *= scale
        _, elements = parse(str(directory / "plate.spice"))
        spice = sum(v for name, nodes, v in elements if name[0].lower() == "c" and
                    v is not None and {node[1] for node in nodes} == {"a", "b"}) * 1e18
        expected = coefficient * side * side
        for stage, got in [("native", native), ("SPICE", spice)]:
            if not math.isfinite(got) or got <= 0 or abs(got - expected) > expected * 1e-5:
                raise ValueError("%s %.7g aF, expected %.7g aF" % (stage, got, expected))
        print("  %-15s ok: %.7g aF" % (name, spice), flush=True)
    except (ValueError, OSError, subprocess.TimeoutExpired) as error:
        print("  %-15s FAIL: %s" % (name, error), flush=True)
        status = 1
sys.exit(status)
