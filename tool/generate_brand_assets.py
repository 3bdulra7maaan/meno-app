from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "assets" / "brand"
FONT = ROOT / "assets" / "fonts" / "Almarai-ExtraBold.ttf"


def mark(size: int) -> Image.Image:
    scale = size / 512
    image = Image.new("RGBA", (size, size), (18, 18, 18, 255))
    draw = ImageDraw.Draw(image)
    radius = round(116 * scale)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill="#121212")
    bubble = [round(value * scale) for value in (60, 120, 452, 374)]
    draw.rounded_rectangle(bubble, radius=round(56 * scale), fill="#D9A752")
    draw.polygon(
        [
            (round(182 * scale), round(355 * scale)),
            (round(163 * scale), round(445 * scale)),
            (round(278 * scale), round(355 * scale)),
        ],
        fill="#D9A752",
    )
    font = ImageFont.truetype(str(FONT), round(144 * scale))
    draw.text(
        (round(256 * scale), round(248 * scale)),
        "M",
        font=font,
        fill="#121212",
        anchor="mm",
        stroke_width=0,
    )
    return image


def wordmark(text_color: str = "#121212") -> Image.Image:
    image = Image.new("RGBA", (620, 140), (0, 0, 0, 0))
    icon = mark(124)
    image.alpha_composite(icon, (8, 8))
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(str(FONT), 82)
    draw.text((154, 71), "Meno", font=font, fill=text_color, anchor="lm")
    return image


def main() -> None:
    BRAND.mkdir(parents=True, exist_ok=True)
    mark(512).save(BRAND / "meno-mark.png", optimize=True)
    wordmark().save(BRAND / "meno-wordmark.png", optimize=True)
    wordmark("#FFFFFF").save(BRAND / "meno-wordmark-on-dark.png", optimize=True)
    icon_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in icon_sizes.items():
        target = ROOT / "android" / "app" / "src" / "main" / "res" / folder
        target.mkdir(parents=True, exist_ok=True)
        mark(size).save(target / "ic_launcher.png", optimize=True)
    splash_target = (
        ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi"
    )
    splash_target.mkdir(parents=True, exist_ok=True)
    mark(192).save(splash_target / "launch_mark.png", optimize=True)
    screenshots = ROOT / "docs" / "screenshots" / "v1_2"
    screenshots.mkdir(parents=True, exist_ok=True)
    mark(1024).save(screenshots / "app-icon.png", optimize=True)


if __name__ == "__main__":
    main()
