# Genera las portadas de album (AlbumImages) y las imagenes de artista (ArtistImages)
# que el script de base de datos referencia pero que no venian en los assets.
# Diseno: gradientes + patrones geometricos en la familia del verde de la aplicacion.
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import os, math

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALBUMS = os.path.join(BASE, "AlbumImages")
ARTISTS = os.path.join(BASE, "ArtistImages")
os.makedirs(ALBUMS, exist_ok=True)
os.makedirs(ARTISTS, exist_ok=True)

FONT_CANDIDATES = [
    r"C:\Windows\Fonts\segoeuib.ttf",
    r"C:\Windows\Fonts\arialbd.ttf",
    r"C:\Windows\Fonts\arial.ttf",
    r"C:\Windows\Fonts\calibrib.ttf",
    r"C:\Windows\Fonts\seguisb.ttf",
]

def load_font(size):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()

SIZE = 640

def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))

def vertical_gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", (1, h))
    px = img.load()
    for y in range(h):
        px[0, y] = lerp(top, bottom, y / max(1, h - 1))
    return img.resize((w, h))

def diagonal_gradient(size, c1, c2):
    w, h = size
    img = Image.new("RGB", (w, h))
    d1, d2 = ImageDraw.Draw(img), None
    for y in range(h):
        for_x = lerp(c1, c2, y / max(1, h - 1))
        d1.line([(0, y), (w, y)], fill=for_x)
    return img

def radial_glow(img, center, radius, color, alpha=90):
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    steps = 40
    for i in range(steps, 0, -1):
        r = radius * i / steps
        a = int(alpha * (1 - i / steps) ** 1.6)
        d.ellipse([center[0] - r, center[1] - r, center[0] + r, center[1] + r], fill=color + (a,))
    return Image.alpha_composite(img.convert("RGBA"), overlay)

def add_grain(img, amount=6):
    import random
    random.seed(7)
    noise = Image.new("RGBA", img.size)
    px = noise.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            v = random.randint(-amount, amount)
            px[x, y] = (v, v, v, 18)
    return Image.alpha_composite(img.convert("RGBA"), noise).convert("RGB")

def vinylish_rings(img, color, center=None, spacing=26):
    """anillos concentricos (estilo vinilo)"""
    w, h = img.size
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = center or (w * 0.78, h * 0.26)
    for r in range(24, max(w, h), spacing):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color + (28,), width=2)
    return img

def wave_bands(img, color, bands=9):
    w, h = img.size
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    for i in range(bands):
        y = h * (0.15 + 0.62 * i / bands)
        amp = 26 + 12 * math.sin(i)
        pts = []
        for x in range(0, w + 8, 8):
            pts.append((x, y + amp * math.sin(x / 70.0 + i * 0.7)))
        d.line(pts, fill=color + (70,), width=4)
    return Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")

def bars(img, color, count=22):
    w, h = img.size
    d = ImageDraw.Draw(img, "RGBA")
    import random
    random.seed(11)
    for i in range(count):
        x = 40 + i * (w - 80) / count
        bh = h * (0.18 + 0.34 * random.random())
        d.rounded_rectangle([x, h - bh - 40, x + 10, h - 40], radius=5, fill=color + (140,))
    return img

def cover_ring_poly(img, color):
    w, h = img.size
    d = ImageDraw.Draw(img, "RGBA")
    rots = 6
    for i in range(rots):
        a0 = (2 * math.pi / rots) * i + 0.35
        cx1, cy1 = w / 2 + 190 * math.cos(a0), h / 2 + 190 * math.sin(a0)
        d.polygon([(cx1, cy1), (cx1 + 120, cy1 + 44), (cx1 + 40, cy1 + 150)], fill=color + (34,))
    return img

ALBUM_STYLES = [
    dict(name="Rock Album",         year=1976, c1=(11, 74, 46),   c2=(4, 26, 16),  accent=(46, 213, 118),  style="rings"),
    dict(name="Relax Music",        year=2000, c1=(13, 92, 74),   c2=(6, 40, 32),  accent=(120, 240, 190), style="waves"),
    dict(name="Retro Album Music",  year=1980, c1=(8, 60, 58),    c2=(3, 22, 26),  accent=(64, 226, 200),  style="bars"),
    dict(name="Classic Album",      year=1950, c1=(20, 66, 52),   c2=(5, 28, 20),  accent=(212, 255, 120), style="poly"),
    dict(name="Country Album",      year=1990, c1=(17, 88, 44),   c2=(7, 34, 18),  accent=(34, 226, 96),   style="rings"),
]

def make_album(cfg, index):
    img = diagonal_gradient((SIZE, SIZE), cfg["c1"], cfg["c2"])
    img = radial_glow(img, (SIZE * 0.78, SIZE * 0.22), 300, (255, 255, 255), alpha=26)
    if cfg["style"] == "rings":
        img = vinylish_rings(img, cfg["accent"])
    elif cfg["style"] == "waves":
        img = wave_bands(img, cfg["accent"])
    elif cfg["style"] == "bars":
        img = bars(img, cfg["accent"])
    else:
        img = cover_ring_poly(img, cfg["accent"])
        img = vinylish_rings(img, cfg["accent"], center=(SIZE * 0.24, SIZE * 0.74), spacing=34)

    d = ImageDraw.Draw(img, "RGBA")
    # marco sutil
    d.rounded_rectangle([18, 18, SIZE - 18, SIZE - 18], radius=26, outline=(255, 255, 255, 40), width=2)
    # banda inferior para el texto
    d.rectangle([0, SIZE - 150, SIZE, SIZE], fill=(0, 0, 0, 120))

    f_title = load_font(58)
    f_sub = load_font(30)
    d.text((44, SIZE - 128), cfg["name"].upper(), font=f_title, fill=(255, 255, 255))
    d.text((46, SIZE - 62), str(cfg["year"]) + "  ·  PoliMusic", font=f_sub, fill=(200, 235, 214))

    img = add_grain(img)
    out = os.path.join(ALBUMS, "album%d.png" % index)
    img.save(out, "PNG", optimize=True)
    return out

ARTIST_STYLES = [
    ("Juan", "Gabriel", (12, 78, 56)),
    ("Ana", "Gabriel", (10, 64, 78)),
    ("Mariah", "Carey", (58, 74, 16)),
    ("Elvis", "Presley", (8, 46, 44)),
    ("Edward", "Sheeran", (16, 88, 40)),
]

def make_artist(first, last, accent, index):
    img = diagonal_gradient((SIZE, SIZE), lerp(accent, (0, 0, 0), 0.30), lerp(accent, (0, 0, 0), 0.72))
    img = radial_glow(img, (SIZE * 0.32, SIZE * 0.30), 300, (255, 255, 255), alpha=34)
    d = ImageDraw.Draw(img, "RGBA")

    # "silueta" de retrato: hombros + cabeza, dando sensacion de artista
    cx = SIZE / 2
    d.ellipse([cx - 108, SIZE * 0.16, cx + 108, SIZE * 0.16 + 216], fill=(255, 255, 255, 236))
    d.ellipse([cx - 196, SIZE * 0.16 + 250, cx + 196, SIZE * 0.16 + 620], fill=(255, 255, 255, 236))
    # iniciales sobre la silueta
    f_init = load_font(190)
    initials = (first[:1] + last[:1]).upper()
    tw = d.textlength(initials, font=f_init)
    accent_dark = lerp(accent, (0, 0, 0), 0.55)
    d.text((cx - tw / 2, SIZE * 0.42), initials, font=f_init, fill=accent_dark)

    # nombre en el pie
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rectangle([0, SIZE - 150, SIZE, SIZE], fill=(0, 0, 0, 128))
    img = Image.alpha_composite(img.convert("RGBA"), overlay)
    d = ImageDraw.Draw(img, "RGBA")
    d.text((36, SIZE - 112), (first + " " + last).upper(), font=load_font(48), fill=(255, 255, 255))

    img = add_grain(img, 4)
    out = os.path.join(ARTISTS, "artist%d.jpg" % index)
    img.convert("RGB").save(out, "JPEG", quality=88, optimize=True)
    return out

created = []
for i, cfg in enumerate(ALBUM_STYLES, start=1):
    created.append(make_album(cfg, i))
for i, (first, last, accent) in enumerate(ARTIST_STYLES, start=1):
    created.append(make_artist(first, last, accent, i))

for p in created:
    print("creado:", p, os.path.getsize(p) // 1024, "KB")
