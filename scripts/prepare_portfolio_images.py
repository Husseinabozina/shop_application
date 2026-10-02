"""Cache public sample photos for deterministic app screenshots; no Firebase access."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import re
from urllib.parse import urlparse
from urllib.request import urlopen

source = Path('lib/features/catalog/domain/entities/sample_product.dart').read_text()
urls = re.findall(r'https://images\.unsplash\.com/[^\s\x27]+', source)
target = Path('build/portfolio-images')
target.mkdir(parents=True, exist_ok=True)

def cache(url):
    with urlopen(url, timeout=30) as response:
        data = response.read(2 * 1024 * 1024)
    (target / (urlparse(url).path.split('/')[-1] + '.jpg')).write_bytes(data)

with ThreadPoolExecutor(max_workers=4) as pool:
    list(pool.map(cache, urls))
print(f'Cached {len(urls)} public sample photos for portfolio screenshots.')
