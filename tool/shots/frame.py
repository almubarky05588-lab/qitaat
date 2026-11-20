# يضيف شريط حالة آيفون أعلى كل صورة → 1290×2796 (مقاس 6.7/6.9 إنش)
import glob, os
from PIL import Image, ImageDraw, ImageFont
os.makedirs('out', exist_ok=True)
BG = (246, 238, 227); INK = (42, 32, 23)
try:
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 50)
except Exception:
    font = ImageFont.load_default()
for f in sorted(glob.glob('raw/*.png')):
    shot = Image.open(f).convert('RGB')
    out = Image.new('RGB', (1290, 2796), BG)
    out.paste(shot.resize((1290, 2796 - 141)), (0, 141))
    d = ImageDraw.Draw(out)
    d.text((150, 46), '9:41', fill=INK, font=font)
    x = 1290 - 150
    d.rounded_rectangle((x - 78, 52, x, 90), radius=10, outline=INK, width=4)
    d.rounded_rectangle((x - 72, 58, x - 10, 84), radius=6, fill=INK)
    d.rectangle((x + 4, 64, x + 9, 78), fill=INK)
    for i, h in enumerate((12, 19, 26, 33)):
        bx = x - 210 + i * 16
        d.rounded_rectangle((bx, 88 - h, bx + 10, 88), radius=3, fill=INK)
    out.save('out/' + os.path.basename(f))
    print('framed', f)
