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
    font = ImageFont.truetype(str(FONT), round(350 * scale))
    draw.text(
        (round(256 * scale), round(245 * scale)),
        "?",
        font=font,
        fill="#D9A752",
        anchor="mm",
    )
    return image


def wordmark(text_color: str = "#121212") -> Image.Image:
    image = Image.new("RGBA", (430, 120), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(str(FONT), 86)
    draw.text((8, 60), "Meno", font=font, fill=text_color, anchor="lm")
    return image


def main() -> None:
    BRAND.mkdir(parents=True, exist_ok=True)
    mark(512).save(BRAND / "meno-mark.png", optimize=True)
    wordmark().save(BRAND / "meno-wordmark.png", optimize=True)
    wordmark("#D9A752").save(BRAND / "meno-wordmark-on-dark.png", optimize=True)
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
    screenshots = ROOT / "docs" / "screenshots" / "v1_2_1"
    screenshots.mkdir(parents=True, exist_ok=True)
    mark(1024).save(screenshots / "app-icon.png", optimize=True)


if __name__ == "__main__":
    main()
