#!/usr/bin/env python3
"""Package only MyShop's public portfolio files for static hosting."""
from pathlib import Path
import argparse
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'build/portfolio-site')
    args = parser.parse_args()
    output = args.output.resolve()
    if output == ROOT or ROOT in output.parents and 'build' not in output.relative_to(ROOT).parts:
        parser.error('Choose a build directory, not a source directory.')
    output.mkdir(parents=True, exist_ok=True)
    for name in ('index.html', 'styles.css', 'showcase.js'):
        shutil.copyfile(ROOT / 'portfolio' / name, output / name)
    assets = output / 'assets'
    assets.mkdir(exist_ok=True)
    for source, name in [
        ('assets/branding/myshop-icon.png','myshop-icon.png'),
        ('assets/fonts/Lato-Regular.ttf','Lato-Regular.ttf'),
        ('assets/fonts/Lato-Bold.ttf','Lato-Bold.ttf'),
        ('assets/onboarding/orders.png','orders-art.png'),
        ('docs/showcase/myshop-demo.mp4','myshop-demo.mp4'),
    ]:
        shutil.copyfile(ROOT / source, assets / name)
    shutil.copytree(ROOT / 'docs/showcase/screens', assets / 'screens', dirs_exist_ok=True)
    (output / '.nojekyll').touch()
    html = (output / 'index.html').read_text()
    js = (output / 'showcase.js').read_text()
    references = re.findall(r'(?:src|href|poster)="([^"#]+)"', html)
    references += [f'assets/screens/{name}.png' for name in re.findall(r"file:'([^']+)'", js)]
    missing = [ref for ref in references if not ref.startswith(('https:', 'data:')) and not (output / ref).is_file()]
    if missing:
        raise SystemExit(f'Missing public assets: {missing}')
    print(json.dumps({'output':str(output),'files':sum(p.is_file() for p in output.rglob('*')),'validated_references':len(references)}))

if __name__ == '__main__':
    main()
