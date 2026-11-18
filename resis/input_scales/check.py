#!/usr/bin/env python3
"""Equivalent .ext unit representations must produce the same RC network."""
from decimal import Decimal
from pathlib import Path
import math
import os
import re
import shlex
import shutil
import subprocess
import sys

TESTDIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TESTDIR.parent.parent / "common"))
from spicenet import parse, read_lines

magic, pdk, work, flat = sys.argv[1:]
work = Path(work)
rc = str(Path(pdk) / "sky130A/libs.tech/magic/sky130A.magicrc")


def run(directory, script, mode="ports", tech=None):
    path = directory / "run.tcl"
    if tech is not None:
        script = "tech load {%s}\n" % tech + script
    path.write_text(script)
    command = shlex.split(magic) + ["-dnull", "-noconsole", "-rcfile", rc, str(path)]
    if os.environ.get("VALGRIND"):
        command = ["valgrind", "--trace-children=yes",
                   "--log-file=" + str(work / ("valgrind." + directory.name + ".%p.log"))] + command
    with (directory / "magic.log").open("w") as output:
        proc = subprocess.run(command, cwd=directory, stdout=output,
                              stderr=subprocess.STDOUT,
                              env=dict(os.environ, FIXTURE_MODE=mode), timeout=60)
    text = (directory / "magic.log").read_text()
    if proc.returncode or "INPUT_SCALES_DONE" not in text or "ERROR: AddressSanitizer" in text:
        raise RuntimeError("magic did not finish: " + str(directory))
    return text


def network(path):
    _, elements = parse(str(path))
    result = []
    for name, nodes, value in elements:
        if name[0].lower() in "mx":
            continue
        if name[0].lower() not in "rc" or value is None or not math.isfinite(value):
            raise RuntimeError("unexpected element in " + str(path))
        result.append((name[0].lower(), tuple(sorted(n for _, n in nodes)), value))
    for words in read_lines(path):
        if words[0][0].lower() in "mx":
            # Keep terminal ordering, model, and all device parameters.
            result.append((words[0][0].lower(), tuple(words[1:]), 0.0))
    if not result:
        raise RuntimeError("empty netlist: " + str(path))
    return sorted(result)


def same(left, right, description):
    if len(left) != len(right):
        raise RuntimeError(description + ": element count changed")
    for a, b in zip(left, right):
        if a[:2] != b[:2] or not math.isclose(a[2], b[2], rel_tol=1e-5, abs_tol=1e-21):
            raise RuntimeError(description + ": %r != %r" % (a, b))


def prepare(directory, source, cap_factor=1, res_factor=1):
    directory.mkdir()
    shutil.copyfile(source / "pair.mag", directory / "pair.mag")
    result = []
    for line in (source / "pair.ext").read_text().splitlines():
        words = line.split()
        if words and words[0] == "scale":
            words[1] = str(Decimal(words[1]) * Decimal(str(res_factor)))
            words[2] = str(Decimal(words[2]) * cap_factor)
        elif words and words[0] in ("node", "substrate"):
            resistance = Decimal(words[2]) / Decimal(str(res_factor))
            if resistance != int(resistance):
                raise RuntimeError("resistance rescaling would lose resolution")
            words[2] = str(int(resistance))
            words[3] = str(Decimal(words[3]) / cap_factor)
        elif words and words[0] == "cap":
            words[3] = str(Decimal(words[3]) / cap_factor)
        else:
            result.append(line)
            continue
        result.append(" ".join(words))
    (directory / "pair.ext").write_text("\n".join(result) + "\n")


try:
    # flat_tech (common.sh) has already expanded any "include" lines.
    tech = Path(flat)
    alternate_tech = work / "sky130A-output-scale.tech"
    content, count = re.subn(r"(?m)^([ \t]*cscale[ \t]+)([0-9]+)",
                             lambda m: m[1] + str(int(m[2]) * 1000), tech.read_text())
    if count != 1:
        raise RuntimeError("expected one capacitance scale in the technology, found %d" % count)
    alternate_tech.write_text(content)
    script = """crashbackups stop
drc off
load pair
select top cell
ext2spice cthresh 0
ext2spice extresist off
ext2spice -o reference.spice
extresist threshold 0
extresist minres 0
extresist mindelay 0
extresist
ext2spice extresist on
ext2spice -o extracted.spice
puts INPUT_SCALES_DONE
quit -noprompt
"""
    sources = {}
    for mode in ("ports", "fets"):
        source = work / (mode + "_source")
        source.mkdir()
        sources[mode] = source
        run(source, (TESTDIR / "layout.tcl").read_text(), mode=mode)
        if not any(line.startswith("cap ") for line in (source / "pair.ext").read_text().splitlines()):
            raise RuntimeError("fixture has no coupling capacitor")
        reference = extracted = None
        for factor in (1, 10, 1000):
            directory = work / (mode + "_cap_" + str(factor))
            prepare(directory, source, cap_factor=factor)
            run(directory, script)
            current_reference = network(directory / "reference.spice")
            current_extracted = network(directory / "extracted.spice")
            if sum(row[0] == "r" for row in current_extracted) < 2:
                raise RuntimeError("resistance extraction did not produce both wires")
            if mode == "fets" and 'killnode ' not in (directory / "pair.res.ext").read_text():
                raise RuntimeError("device fixture did not exercise killed-node coupling")
            if reference is None:
                reference, extracted = current_reference, current_extracted
            else:
                same(reference, current_reference, "reference C units")
                same(extracted, current_extracted, "distributed RC units")
            print("  %s, cap scale x%d: same physical RC network" % (mode, factor))
        directory = work / (mode + "_output_scale")
        prepare(directory, source)
        run(directory, script, tech=alternate_tech)
        current_reference = network(directory / "reference.spice")
        current_extracted = network(directory / "extracted.spice")
        same(reference, current_reference, "reference after output scale change")
        same(extracted, current_extracted, "distributed RC after output scale change")
        input_scale = next(line.split()[2] for line in (source / "pair.ext").read_text().splitlines()
                           if line.startswith("scale "))
        output_scale = next(line.split()[2] for line in (directory / "pair.res.ext").read_text().splitlines()
                            if line.startswith("scale "))
        if int(output_scale) != int(input_scale) * 1000:
            raise RuntimeError("output scale did not actually change")
        print("  %s, output scale x1000: same physical RC network" % mode)
    for factor in (1, Decimal("0.1")):
        directory = work / ("res_" + str(factor))
        prepare(directory, sources["ports"], res_factor=factor)
        text = run(directory, script.replace("extresist threshold 0\n",
                                             "extresist threshold 20000\n"))
        counts = re.findall(r"Nets extracted:\s*(\d+)", text)
        if counts != ["0"]:
            raise RuntimeError("equivalent R units changed threshold eligibility: " + str(counts))
        print("  resistance scale x%s: same cutoff decision" % factor)
except Exception as error:
    print("  FAIL:", error)
    sys.exit(1)
