"""Print a deterministic code manifest; logs, results and data are never included."""
import argparse
import hashlib
import os
from pathlib import Path


AWS_PATH = Path("biomedical/v0.5/aws")


def files(root, scope):
    if scope == "gptr":
        return sorted({root / "DESCRIPTION", root / "NAMESPACE",
            *[p for folder in ("R", "inst") for p in (root / folder).rglob("*")
              if p.is_file()]})
    aws = root / AWS_PATH
    return sorted({aws / "links.tsv", *[p for p in aws.rglob("*")
        if p.is_file() and p.suffix in (".R", ".py", ".sh", ".json")
        and ".zh-CN." not in p.name and "__pycache__" not in p.parts]})


def manifest(root, scope):
    records = {}
    for path in files(root, scope):
        records[str(path.relative_to(root))] = hashlib.sha256(path.read_bytes()).hexdigest()
    if scope == "benchmark":
        for line in (root / AWS_PATH / "links.tsv").read_text().splitlines():
            old, new = line.split("\t")
            path = root / old
            records[old] = "link:" + str(path.readlink())
    return "".join(f"{value}  {path}\n" for path, value in sorted(records.items()))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scope", choices=("benchmark", "gptr"))
    parser.add_argument("--root", type=Path, default=None)
    args = parser.parse_args()
    root = args.root or (Path(os.environ["GPTR_SOURCE"]) if args.scope == "gptr" else Path(__file__).resolve().parents[3])
    print(manifest(root.resolve(), args.scope), end="")
