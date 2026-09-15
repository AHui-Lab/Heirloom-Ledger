"""Convert the generated checkerboard preview around atlas subjects to alpha.

The image service returned RGB PNGs with a visible checkerboard instead of an
alpha channel.  This keeps the generated subjects and removes only the
border-connected, neutral light checkerboard pixels in each atlas cell.
"""

from collections import deque
from pathlib import Path

from PIL import Image


def is_background(pixel: tuple[int, int, int]) -> bool:
    r, g, b = pixel
    return r >= 185 and max(pixel) - min(pixel) <= 12


def clean_atlas(source: Path, target: Path, columns: int, rows: int) -> None:
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    cell_width = width // columns
    cell_height = height // rows
    pixels = image.load()

    for row in range(rows):
        for column in range(columns):
            left = column * cell_width
            top = row * cell_height
            right = min(width, left + cell_width)
            bottom = min(height, top + cell_height)
            queue: deque[tuple[int, int]] = deque()
            seen: set[tuple[int, int]] = set()

            for x in range(left, right):
                queue.extend(((x, top), (x, bottom - 1)))
            for y in range(top, bottom):
                queue.extend(((left, y), (right - 1, y)))

            while queue:
                x, y = queue.popleft()
                if (x, y) in seen or not (left <= x < right and top <= y < bottom):
                    continue
                seen.add((x, y))
                if not is_background(pixels[x, y][:3]):
                    continue
                pixels[x, y] = (*pixels[x, y][:3], 0)
                queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))

    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)


def clean_isolated_layer(source: Path, target: Path, neutral_floor: int = 135) -> None:
    """Remove a baked neutral checkerboard from an isolated generated asset.

    Unlike atlas cells, large transparent scene layers can contain faint neutral
    checker squares that are disconnected from the canvas edge.  They must not
    survive as opaque dust over the game background.  The intended assets use
    chromatic brown, blue and beige materials, so only near-neutral light pixels
    are removed globally.
    """
    image = Image.open(source).convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, _ = pixels[x, y]
            if min(r, g, b) >= neutral_floor and max(r, g, b) - min(r, g, b) <= 14:
                pixels[x, y] = (r, g, b, 0)
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)


def normalize_portrait_cell(source: Path, target: Path, column: int, row: int) -> None:
    """Promote one 4x2 portrait-atlas cell to the standard 1024x1536 canvas."""
    atlas = Image.open(source).convert("RGBA")
    cell_width = atlas.width // 4
    cell_height = atlas.height // 2
    cell = atlas.crop((column * cell_width, row * cell_height, (column + 1) * cell_width, (row + 1) * cell_height))
    alpha_bounds = cell.getchannel("A").getbbox()
    if alpha_bounds is not None:
        cell = cell.crop(alpha_bounds)
    scale = min(860 / cell.width, 1120 / cell.height)
    cell = cell.resize((max(1, round(cell.width * scale)), max(1, round(cell.height * scale))), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (1024, 1536), (0, 0, 0, 0))
    canvas.alpha_composite(cell, ((canvas.width - cell.width) // 2, 300))
    target.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(target)


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    clean_atlas(root / "assets/portraits-v3.png", root / "assets/portraits-v3-alpha.png", 4, 2)
    clean_atlas(root / "assets/objects-v3.png", root / "assets/objects-v3-alpha.png", 6, 4)
