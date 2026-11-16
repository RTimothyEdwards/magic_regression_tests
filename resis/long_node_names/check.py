#!/usr/bin/env python3
"""Long names must remain distinct and give the same physical network."""
from pathlib import Path
import math
import os
import shlex
import subprocess
import sys

testdir = Path(__file__).resolve().parent
sys.path.insert(0, str(testdir.parent.parent / "common"))
from spicenet import parse, effective_resistance

magic, pdk, work = sys.argv[1:]
work = Path(work)
rc = str(Path(pdk) / "sky130A/libs.tech/magic/sky130A.magicrc")

try:
    references = {}
    for mode, length in [("wire", 64), ("wire", 999), ("wire", 1100),
                         ("fets", 64), ("fets", 1100)]:
        directory = work / ("%s_%d" % (mode, length))
        directory.mkdir()
        env = dict(os.environ, NAME_LENGTH=str(length), MODE=mode)
        env.setdefault("ASAN_OPTIONS", "detect_leaks=0:abort_on_error=1")
        command = shlex.split(magic) + ["-dnull", "-noconsole", "-rcfile", rc,
                                       str(testdir / "layout.tcl")]
        if os.environ.get("VALGRIND"):
            command = ["valgrind", "--trace-children=yes",
                       "--log-file=" + str(work / ("valgrind." + directory.name + ".%p.log"))] + command
        with (directory / "magic.log").open("w") as output:
            proc = subprocess.run(command, cwd=directory, stdout=output,
                                  stderr=subprocess.STDOUT, env=env, timeout=60)
        text = (directory / "magic.log").read_text(errors="replace")
        if proc.returncode or "LONG_NAMES_DONE" not in text or "ERROR: AddressSanitizer" in text:
            raise RuntimeError("magic did not finish cleanly: " + directory.name)
        netlist = directory / "extracted.spice"
        subckts, elements = parse(str(netlist))
        if not any(n[0].lower().startswith("r") for n in elements):
            raise RuntimeError("no wire resistors in " + directory.name)
        prefix = "n" * length
        suffixes = ("_in", "_out", "_mid") if mode == "wire" else ("_d1", "_d2")
        nodes = {node for _, endpoints, _ in elements for _, node in endpoints}
        if not all(prefix + suffix in nodes for suffix in suffixes):
            raise RuntimeError("a full terminal name is missing or truncated")
        normalized = sorted(
            (name[0].lower(), tuple(node.replace(prefix, "NET") for _, node in endpoints), value)
            for name, endpoints, value in elements
        )
        if mode not in references:
            references[mode] = normalized
        else:
            expected = references[mode]
            if len(expected) != len(normalized):
                raise RuntimeError("name length changed the element count")
            for a, b in zip(expected, normalized):
                if a[:2] != b[:2] or (a[2] != b[2] and
                        (a[2] is None or b[2] is None or not math.isclose(a[2], b[2], rel_tol=1e-5))):
                    raise RuntimeError("name length changed the physical network")
        if mode == "wire":
            cell = subckts[-1][0] if subckts else ""
            for suffix in ("_out", "_mid"):
                resistance = effective_resistance(elements, (cell, prefix + "_in"),
                                                   (cell, prefix + suffix))
                if resistance is None or resistance <= 0:
                    raise RuntimeError("a long named port became disconnected")
        print("  %s, %d characters: complete names and unchanged network" % (mode, length))
except Exception as error:
    print("  FAIL:", error)
    sys.exit(1)
