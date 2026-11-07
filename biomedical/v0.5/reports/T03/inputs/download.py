"""Download the exact public native inputs; validate SHA-256 before use."""
import argparse
import csv
import hashlib
from pathlib import Path
import shutil
import urllib.request

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('destination', type=Path)
args = parser.parse_args()
args.destination.mkdir(parents=True, exist_ok=True)
source = Path(__file__).resolve().parent
for row in csv.DictReader((source / 'manifest.csv').open()):
    target = args.destination / row['filename']
    if target.exists() and hashlib.sha256(target.read_bytes()).hexdigest() == row['sha256']:
        continue
    partial = target.with_suffix('.download')
    with urllib.request.urlopen(row['url'], timeout=180) as response, partial.open('wb') as output:
        shutil.copyfileobj(response, output)
    if hashlib.sha256(partial.read_bytes()).hexdigest() != row['sha256']:
        partial.unlink()
        raise ValueError('Checksum mismatch: ' + row['filename'])
    partial.replace(target)
    print(target.name, flush=True)
shutil.copyfile(source / 'input-files.txt', args.destination / 'input-files.txt')
