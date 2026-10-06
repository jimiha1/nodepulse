#!/usr/bin/env python3
"""Draws the NodePulse app icon: a heartbeat line on navy.

Checked in rather than run at build time, because the assets are what ships and
a build should not need a drawing tool. Re-run it after changing anything here:

    py scripts/gen_app_icon.py

Every size is the same waveform, so the shape lives once in a unit square and
each output is a supersampled raster of it. The PNGs are written by hand for
the reason the drawing is: this repo's machines have no drawing tool, and a
flat RGBA image is a zlib stream and four chunks.
"""

import struct
import zlib
from pathlib import Path

# The waveform, in a unit square. A flat lead-in, one spike, a flat lead-out.
# The spike is deliberately narrow and tall: at 40 px the launcher shows, a
# gentler one would blur into a smudge.
WAVE = [
    (0.20, 0.50),  # lead-in start
    (0.36, 0.50),  # lead-in end
    (0.44, 0.28),  # spike up
    (0.58, 0.72),  # spike down, below the baseline
    (0.66, 0.50),  # back to baseline
    (0.82, 0.50),  # lead-out end
]
STROKE = 0.075          # stroke width, in unit-square terms
BG = (0x1A, 0x3D, 0x5C)  # #1A3D5C
FG = (0xFF, 0xFF, 0xFF)

SAMPLES = 4             # 4x4 subsamples a pixel; the diagonals need them
SAFE = 0.66             # adaptive icons crop, so the foreground insets to this

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

_HALF = STROKE / 2
_HALF2 = _HALF * _HALF


def capsules():
    """Each stroke segment as (start, direction, inverse length², bounds).

    The bounds are the segment's box grown by half the stroke: a sample outside
    them cannot be inside the capsule, and skipping those first is what keeps a
    432 px render quick in plain Python. Round caps and joins need no code of
    their own — the union of the five capsules is exactly the stroke.
    """
    out = []
    for (ax, ay), (bx, by) in zip(WAVE, WAVE[1:]):
        dx, dy = bx - ax, by - ay
        out.append((
            ax, ay, dx, dy, 1.0 / (dx * dx + dy * dy),
            min(ax, bx) - _HALF, min(ay, by) - _HALF,
            max(ax, bx) + _HALF, max(ay, by) + _HALF,
        ))
    return out


SEGMENTS = capsules()


def covered(x: float, y: float) -> bool:
    """Whether a point in the unit square lies under the stroke."""
    for ax, ay, dx, dy, inv, minx, miny, maxx, maxy in SEGMENTS:
        if x < minx or x > maxx or y < miny or y > maxy:
            continue
        t = ((x - ax) * dx + (y - ay) * dy) * inv
        t = 0.0 if t < 0.0 else 1.0 if t > 1.0 else t
        ex, ey = x - (ax + t * dx), y - (ay + t * dy)
        if ex * ex + ey * ey <= _HALF2:
            return True
    return False


def render(size: int, inset: bool = False, fill: bool = True) -> bytes:
    """One output's RGBA pixels.

    `inset` draws the waveform at SAFE of its size, centred: the adaptive
    foreground is cropped to a shape the launcher picks, and a full-bleed line
    would lose its ends under a circular mask. `fill` paints the navy
    background; without it the waveform stands alone in white on transparent,
    which is what the themed-icon and foreground layers are.
    """
    scale = SAFE if inset else 1.0
    # A subsample's coordinate in the unit square, per pixel index. The same
    # list serves both axes, so it is built once rather than per pixel.
    axis = [
        [0.5 + ((i + (s + 0.5) / SAMPLES) / size - 0.5) / scale
         for s in range(SAMPLES)]
        for i in range(size)
    ]
    pixels = bytearray()
    for y in range(size):
        row = axis[y]
        for x in range(size):
            cols = axis[x]
            hits = sum(covered(u, v) for v in row for u in cols)
            a = hits / SAMPLES ** 2
            if fill:
                pixels += bytes(
                    round(BG[i] + (FG[i] - BG[i]) * a) for i in range(3)
                ) + b"\xff"
            else:
                pixels += bytes(FG) + bytes((round(a * 255),))
    return bytes(pixels)


def png(width: int, height: int, pixels: bytes) -> bytes:
    """An 8-bit RGBA PNG: signature, three chunks, a CRC32 per chunk.

    Filter 0 on every scanline: the artwork is flat enough that zlib finds the
    rows without the predictor filters' help.
    """
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw += b"\x00"
        raw += pixels[y * stride:(y + 1) * stride]

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )


def main() -> None:
    """Every variant, at every density, in the paths the platforms read."""
    outputs = [(ASSETS / "app_icon.png", 512, False, True)]
    for density, size in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                          ("xxhdpi", 144), ("xxxhdpi", 192)):
        folder = RES / f"mipmap-{density}"
        outputs += [
            (folder / "ic_launcher.png", size, False, True),
            (folder / "ic_launcher_round.png", size, False, True),
            # Themed icons are the waveform alone; the system supplies a colour.
            (folder / "ic_launcher_monochrome.png", size, False, False),
            # 2.25x the launcher size: the adaptive foreground's own canvas.
            (folder / "ic_launcher_foreground.png", size * 9 // 4, True, False),
        ]

    for path, size, inset, fill in outputs:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png(size, size, render(size, inset, fill)))
        print(f"{path.relative_to(ROOT)}  {path.stat().st_size} bytes")


if __name__ == "__main__":
    main()
