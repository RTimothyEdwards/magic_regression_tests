#!/usr/bin/env python3
"""Analytical overlap/shielding areas, independent of the extractor's tiling."""
import math
import os
from pathlib import Path
import shlex
import subprocess
import sys

TESTDIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TESTDIR.parent.parent / 'common'))
from gdslib import i2, i4, library, rec, structure, text
from spicenet import parse_value

magic, pdk, work, flat = sys.argv[1:]
work = Path(work)
rc = str(Path(pdk) / 'sky130A/libs.tech/magic/sky130A.magicrc')


def polygon(vertices, layer):
    points = [round(v * 1000) for point in vertices + vertices[:1] for v in point]
    return (rec(0x08, 0) + rec(0x0d, 2, i2(layer)) + rec(0x0e, 2, i2(20)) +
            rec(0x10, 3, i4(*points)) + rec(0x11, 0))


def rectangle(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def transform(point, rotation, mirror, offset=(0, 0)):
    x, y = point
    if mirror:
        x = -x
    for _ in range(rotation):
        x, y = -y, x
    return (x + offset[0], y + offset[1])


def run(name, shapes, area, rotation=0, mirror=False, offset=(0, 0)):
    directory = work / name
    directory.mkdir()
    body = b''
    for layer, points, label in shapes:
        vertices = [transform(p, rotation, mirror, offset) for p in points]
        body += polygon(vertices, layer)
        # The vertex mean is strictly inside each convex conductor.
        x, y = [sum(p[i] for p in vertices) / len(vertices) for i in (0, 1)]
        body += text(round(x * 1000), round(y * 1000), label, layer=layer, datatype=5)
    (directory / 'probe.gds').write_bytes(library([structure('probe', body)]))
    script = '''crashbackups stop
drc off
tech load {%s}
gds read probe.gds
load probe
extract do coupling
extract no resistance
extract all
ext2spice lvs
ext2spice cthresh 0
ext2spice -o probe.spice
puts SPLIT_OVERLAP_DONE
quit -noprompt
''' % technology
    (directory / 'run.tcl').write_text(script)
    command = shlex.split(magic) + ['-dnull', '-noconsole', '-rcfile', rc, 'run.tcl']
    if os.environ.get('VALGRIND'):
        command = ['valgrind', '--trace-children=yes',
                   '--log-file=' + str(work / ('valgrind.' + name + '.%p.log'))] + command
    with (directory / 'magic.log').open('w') as f:
        p = subprocess.run(command, cwd=directory, stdout=f, stderr=subprocess.STDOUT, timeout=60)
    log = (directory / 'magic.log').read_text()
    if p.returncode or 'SPLIT_OVERLAP_DONE' not in log:
        raise RuntimeError('incomplete extraction: ' + name)
    # The controlled rule is 1000 aF/um^2, so C in fF equals area in um^2.
    cap = 0.0
    for line in (directory / 'probe.spice').read_text().splitlines():
        row = line.split()
        if row and row[0][0].lower() == 'c':
            if set(row[1:3]) == {'A', 'B'}:
                cap += parse_value(row[3]) * 1e15
    if not math.isclose(cap, area, rel_tol=2e-5, abs_tol=1e-6):
        failures.append('%s: %g fF, expected %g fF' % (name, cap, area))
    # Do not let a correctly sized capacitor to an anonymous conductor
    # hide a port left as a separate zero-area sticky node.
    native_nodes = {}
    for line in (directory / 'probe.ext').read_text().splitlines():
        row = shlex.split(line)
        if row and row[0] == 'node':
            native_nodes[row[1]] = row
    for _, _, label in shapes:
        row = native_nodes.get(label)
        if row is None or not any(float(row[i]) > 0 for i in range(7, len(row), 2)):
            failures.append(name + ': label ' + label + ' not attached to its conductor')
    print('  %s: %g / %g fF' % (name, cap, area))


try:
    # Preserve the process layers, connectivity, units, and device rules,
    # but isolate a single area coefficient from perimeter/fringe models.
    keywords = {'areacap', 'perimc', 'overlap', 'sidewall', 'sideoverlap',
                'defaultareacap', 'defaultperimeter', 'defaultoverlap',
                'defaultsidewall', 'defaultsideoverlap'}
    lines, inside, continuation = [], False, False
    for line in Path(flat).read_text().splitlines():
        words = line.split()
        if words and words[0] == 'extract':
            inside = True
        if inside and words and words[0] == 'end':
            lines += ['variants *', 'units microns', 'areacap metal1,metal5 10',
                      'overlap metal5 metal1 1000 metal2,metal3']
            inside = False
        if inside and (continuation or (words and words[0] in keywords)):
            continuation = line.rstrip().endswith('\\')
            continue
        lines.append(line)
    technology = work / 'overlap-only.tech'
    technology.write_text('\n'.join(lines) + '\n')
    square = rectangle(0, 0, 100, 100)
    sw = [(0, 0), (100, 0), (0, 100)]
    ne = [(100, 0), (100, 100), (0, 100)]
    se = [(0, 0), (100, 0), (100, 100)]
    # Expected areas are elementary rectangles/triangles, written out
    # rather than recomputed with a copy of the C clipping algorithm.
    cases = [
        ('square', square, square, [], 10000),
        ('triangle_rectangle', sw, square, [], 5000),
        ('aligned', sw, sw, [], 5000),
        ('complement', sw, ne, [], 0),
        ('crossing', sw, se, [], 2500),
        ('partial_left', sw, rectangle(0, 0, 50, 100), [], 3750),
        ('touch_only', sw, rectangle(50, 50, 100, 100), [], 0),
        ('offset', sw, [(50, 0), (150, 0), (50, 100)], [], 1250),
        ('unequal_slopes', [(0, 0), (100, 0), (0, 50)], se, [], 5000 / 3),
        ('shield_half', square, square, [(69, sw, 'S')], 5000),
        ('shield_same', sw, sw, [(69, sw, 'S')], 0),
        ('shield_empty_half', sw, sw, [(69, ne, 'S')], 5000),
        ('shield_partial', sw, square, [(69, rectangle(0, 0, 50, 100), 'S')], 1250),
        ('two_shields_union', square, square, [(69, sw, 'S'), (70, se, 'T')], 2500),
        ('two_shields_complement', square, square, [(69, sw, 'S'), (70, ne, 'T')], 0),
        ('two_shields_same', square, square, [(69, sw, 'S'), (70, sw, 'T')], 5000),
    ]
    failures = []
    for name, lower, upper, shields, expected in cases:
        for rotation, mirror in [(0, False), (1, False), (2, False), (3, False),
                                 (0, True), (1, True), (2, True), (3, True)]:
            run('%s_r%d_m%d' % (name, rotation, mirror),
                [(68, lower, 'A'), (72, upper, 'B')] + shields,
                expected, rotation, mirror)
    # Translation must not change the result or lose small overlap areas.
    run('translated_crossing', [(68, sw, 'A'), (72, se, 'B')], 2500, offset=(100000, -100000))
    if failures:
        raise RuntimeError('\n'.join(failures))
except Exception as error:
    print('FAIL:', error)
    sys.exit(1)
