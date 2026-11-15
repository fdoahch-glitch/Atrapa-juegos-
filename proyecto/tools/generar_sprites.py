#!/usr/bin/env python3
"""Genera los sprites PNG (128x128) a partir de la fuente Noto Color Emoji.
Uso: python3 tools/generar_sprites.py [ruta_fuente]
Nombre de archivo = primer punto de código en hexadecimal (ej. 🐱 -> 1f431.png)."""
import sys, os
from PIL import Image, ImageDraw, ImageFont

FUENTE = sys.argv[1] if len(sys.argv) > 1 else "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"
SALIDA = os.path.join(os.path.dirname(__file__), "..", "assets", "emoji")
EMOJIS = ("🐱🐶🦖🐰🦊🐼🤖🧙 🐌👾🐝🦀👻 🌳🌲🌸🌻🍄🌵🏠🏰☁ ⭐💎🏁📍 "
          "❤🔊🔇▶🚀❓✨🖼🧱↩↪📄🧽✋🗑📋➕➖↔🎮🎉😵⬅➡⬆⚙📁🌐🖥📱⏸🔁📑🏆🪙🔧🧊🏃↕🗺✅⏰😕🛡🧲🛒").replace(" ", "")
font = ImageFont.truetype(FUENTE, 109)
os.makedirs(SALIDA, exist_ok=True)
hechos = 0
for ch in EMOJIS:
    img = Image.new("RGBA", (220, 220), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.text((40, 30), ch, font=font, embedded_color=True)
    bb = img.getbbox()
    if not bb:
        print("sin glifo:", ch); continue
    img = img.crop(bb)
    esc = min(120 / img.width, 120 / img.height)
    img = img.resize((max(1, round(img.width * esc)), max(1, round(img.height * esc))), Image.LANCZOS)
    lienzo = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    lienzo.paste(img, ((128 - img.width) // 2, (128 - img.height) // 2), img)
    lienzo.save(os.path.join(SALIDA, "%x.png" % ord(ch)))
    hechos += 1
print("sprites generados:", hechos)
