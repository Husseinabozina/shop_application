#!/usr/bin/env python3
"""Prepare README media from real simulator captures; never redraw app content."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
CAPTURES = {
    'splash': '04.17.15',
    'onboarding-discover': '04.17.21',
    'onboarding-basket': '04.17.24',
    'onboarding-orders': '04.17.30',
    'home': '04.18.18',
    'categories': '04.18.28',
    'product': '04.18.42',
    'cart': '04.19.22',
    'checkout': '04.20.34',
}

def run(binary, *args):
    subprocess.run([str(binary), '-hide_banner', '-loglevel', 'error', *args], check=True)

def save_screen(source, dest):
    with Image.open(source) as im:
        im = im.convert('RGB')
        width = min(900, im.width)
        im = im.resize((width, round(im.height * width / im.width)), Image.Resampling.LANCZOS)
        im.save(dest, optimize=True)

def make_cover(output):
    canvas = Image.new('RGB', (1800, 1020), '#FCF9F5')
    draw = ImageDraw.Draw(canvas)
    ink, brown, muted = '#261D17', '#7A4A2D', '#67594F'
    def font(size, bold=False):
        return ImageFont.truetype(str(ROOT / 'assets/fonts' / ('Lato-Bold.ttf' if bold else 'Lato-Regular.ttf')), size)
    logo = Image.open(ROOT / 'assets/branding/myshop-icon.png').convert('RGBA')
    logo.thumbnail((86, 86), Image.Resampling.LANCZOS)
    canvas.paste(logo, (90, 90), logo)
    draw.text((192, 100), 'MyShop', font=font(48, True), fill=ink)
    draw.text((96, 244), 'A FLUTTER COMMERCE EXPERIENCE', font=font(19, True), fill=brown)
    draw.text((90, 304), 'Good finds.', font=font(102, True), fill=ink)
    draw.text((90, 422), 'Made yours.', font=font(102, True), fill=brown)
    draw.text((96, 608), 'Thoughtful shopping,', font=font(32), fill=muted)
    draw.text((96, 652), 'from first look to last detail.', font=font(32), fill=muted)
    for text, x, width in [('Flutter', 96, 148), ('Firebase', 262, 165), ('Sandbox checkout', 445, 276)]:
        draw.rounded_rectangle((x, 752, x + width, 812), radius=30, fill='#F1DFD1')
        draw.text((x + 23, 768), text, font=font(23, True), fill=brown)
    draw.line((96, 901, 716, 901), fill='#E6DBD1', width=2)
    draw.text((96, 930), 'DISCOVER  /  SAVE  /  CHECK OUT  /  KEEP CLOSE', font=font(17, True), fill=muted)
    for name, x, y, width in [('home', 876, 246, 238), ('onboarding-discover', 1094, 124, 290), ('order-details', 1370, 230, 242)]:
        screen = Image.open(output / 'screens' / f'{name}.png').convert('RGB')
        height = round(screen.height * width / screen.width)
        screen = screen.resize((width, height), Image.Resampling.LANCZOS)
        shadow = Image.new('RGBA', canvas.size)
        ImageDraw.Draw(shadow).rounded_rectangle((x - 10, y, x + width + 10, y + height + 20), radius=42, fill=(67, 38, 19, 36))
        shadow = shadow.filter(ImageFilter.GaussianBlur(18))
        canvas = Image.alpha_composite(canvas.convert('RGBA'), shadow)
        frame = Image.new('RGBA', (width + 14, height + 14))
        ImageDraw.Draw(frame).rounded_rectangle((0, 0, width + 13, height + 13), radius=36, fill='#30241B')
        mask = Image.new('L', screen.size)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height - 1), radius=29, fill=255)
        frame.paste(screen, (7, 7), mask)
        canvas.alpha_composite(frame, (x - 7, y - 7))
    canvas.convert('RGB').save(output / 'readme-cover.png', optimize=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture-dir', type=Path, required=True)
    parser.add_argument('--recording', type=Path, required=True)
    parser.add_argument('--ffmpeg', type=Path, required=True)
    args = parser.parse_args()
    output = ROOT / 'docs/showcase'
    screens = output / 'screens'
    screens.mkdir(parents=True, exist_ok=True)
    provenance = []
    for name, time in CAPTURES.items():
        source = args.capture_dir / f'Simulator Screenshot - iPhone 17 Pro - 2026-10-05 at {time}.png'
        save_screen(source, screens / f'{name}.png')
        provenance.append({'asset': f'screens/{name}.png', 'source': source.name, 'sha256': hashlib.sha256(source.read_bytes()).hexdigest()})
    for name, time in [('order-details', 54.9), ('order-summary', 55.7)]:
        temp = output / f'{name}-source.png'
        run(args.ffmpeg, '-ss', str(time), '-i', str(args.recording), '-frames:v', '1', '-y', str(temp))
        save_screen(temp, screens / f'{name}.png')
        temp.unlink()
        provenance.append({'asset': f'screens/{name}.png', 'source': args.recording.name, 'timestamp_seconds': time})
    # Exclude sign-in, password entry and the delivery address form.
    cuts = [(0.8, 7.0), (19.3, 39.4), (54.1, 57.0)]
    graph = ';'.join(f'[0:v]trim=start={a}:end={b},setpts=PTS-STARTPTS[v{i}]' for i,(a,b) in enumerate(cuts))
    graph += ';' + ''.join(f'[v{i}]' for i in range(len(cuts))) + f'concat=n={len(cuts)}:v=1:a=0,scale=540:-2,fps=30[out]'
    run(args.ffmpeg, '-i', str(args.recording), '-filter_complex', graph, '-map', '[out]', '-an', '-c:v', 'libx264', '-crf', '22', '-preset', 'medium', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', '-y', str(output / 'myshop-demo.mp4'))
    gif_graph = '[0:v]trim=start=0:end=6.2,setpts=PTS-STARTPTS[a];[0:v]trim=start=6.2:end=10.2,setpts=PTS-STARTPTS[b];[a][b]concat=n=2:v=1:a=0,fps=10,scale=300:-1:flags=lanczos,split[x][y];[x]palettegen=stats_mode=diff[p];[y][p]paletteuse=dither=bayer:bayer_scale=3[out]'
    run(args.ffmpeg, '-i', str(output / 'myshop-demo.mp4'), '-filter_complex', gif_graph, '-map', '[out]', '-loop', '0', '-y', str(output / 'preview.gif'))
    make_cover(output)
    (output / 'manifest.json').write_text(json.dumps({'captured_on': '2026-10-05', 'device': 'iPhone 17 Pro simulator', 'recording': args.recording.name, 'recording_sha256': hashlib.sha256(args.recording.read_bytes()).hexdigest(), 'public_video_cuts_seconds': cuts, 'assets': provenance}, indent=2) + '\n')
    for p in sorted(output.rglob('*')):
        if p.is_file(): print(p.relative_to(ROOT), p.stat().st_size)

if __name__ == '__main__':
    main()
