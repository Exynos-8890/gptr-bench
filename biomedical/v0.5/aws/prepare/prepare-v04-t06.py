"""Prepare genuine ENCODE ATAC replicate intervals and GENCODE v44 gene TSSs."""

import argparse
import csv
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time
import urllib.request


def download(url, target):
    if not target.exists():
        request = urllib.request.Request(url, headers={"User-Agent": "gptr-biomedical-benchmark/0.4"})
        temporary = target.with_suffix(target.suffix + ".part")
        with urllib.request.urlopen(request, timeout=120) as response, temporary.open("wb") as out:
            while block := response.read(1 << 20):
                out.write(block)
        temporary.replace(target)
    return {"url": url, "file": target.name, "bytes": target.stat().st_size,
            "sha256": hashlib.file_digest(target.open("rb"), "sha256").hexdigest()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    source, output = args.source_dir.resolve(), args.output_dir.resolve()
    source.mkdir(parents=True, exist_ok=True)
    output.mkdir(parents=True, exist_ok=True)
    sources = []
    metadata = source / "ENCSR214QZO.json"
    sources.append(download("https://www.encodeproject.org/experiments/ENCSR214QZO/?format=json", metadata))
    experiment = json.loads(metadata.read_text())
    accessions = ["ENCFF139WTI", "ENCFF276IWY"]
    for index, accession in enumerate(accessions, 1):
        file = next(x for x in experiment["files"] if x["accession"] == accession)
        if file.get("assembly") != "GRCh38" or file.get("biological_replicates") != [index]:
            raise ValueError("Unexpected assembly or biological replicate; review ENCODE metadata")
        path = source / (accession + ".bed.gz")
        sources.append(download("https://www.encodeproject.org" + file["href"], path))
        with gzip.open(path, "rt") as inp, (output / f"peaks-{index}.tsv").open("w") as out:
            writer = csv.writer(out, delimiter="\t")
            writer.writerow(["chr", "start", "end", "score"])
            for row in csv.reader(inp, delimiter="\t"):
                if row[0] in ["chr" + str(x) for x in range(1, 23)] + ["chrX", "chrY"]:
                    writer.writerow([row[0], int(row[1]) + 1, int(row[2]), float(row[6])])
    gtf = source / "gencode.v44.annotation.gtf.gz"
    sources.append(download("https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_44/"
                            "gencode.v44.annotation.gtf.gz", gtf))
    with gzip.open(gtf, "rt") as inp, (output / "genes.tsv").open("w") as out:
        writer = csv.writer(out, delimiter="\t")
        writer.writerow(["chr", "tss", "gene", "strand"])
        for line in inp:
            if line.startswith("#"):
                continue
            row = line.rstrip().split("\t")
            if row[2] != "gene" or 'gene_type "protein_coding"' not in row[8]:
                continue
            attrs = dict(re.findall(r'(\w+) "([^"]+)"', row[8]))
            writer.writerow([row[0], row[3] if row[6] == "+" else row[4],
                             attrs.get("gene_name", attrs["gene_id"]), row[6]])
    chrom = source / "hg38.chrom.sizes"
    sources.append(download("https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.chrom.sizes", chrom))
    r_code = """
      args=commandArgs(TRUE); output=args[1]; source=args[2]
      peaks=lapply(1:2,function(i) utils::read.delim(file.path(output,paste0('peaks-',i,'.tsv'))))
      genes=utils::read.delim(file.path(output,'genes.tsv'))
      chromosomes=utils::read.delim(file.path(source,'hg38.chrom.sizes'),header=FALSE,
        col.names=c('chr','length'))
      genes=genes[genes$chr %in% unique(peaks[[1]]$chr),]
      genes=genes[order(genes$chr,genes$tss,genes$gene),]
      raw=list(peaks=peaks,genes=genes,chromosomes=chromosomes)
      stopifnot(length(peaks)==2,all(vapply(peaks,nrow,integer(1))>0),nrow(genes)>1000)
      saveRDS(raw,file.path(output,'input.rds'),compress=FALSE)
      jsonlite::write_json(list(replicates=2,peaks=vapply(peaks,nrow,integer(1)),
        genes=nrow(genes)),file.path(output,'dimensions.json'),auto_unbox=TRUE)
    """
    subprocess.run(["Rscript", "--vanilla", "-e", r_code, str(output), str(source)], check=True)
    data = output / "input.rds"
    manifest = {"synthetic": False, "fully_resident": True, "task": "T06", "prepared_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "source": "ENCODE ENCSR214QZO; GENCODE v44 GRCh38",
                "sources": sources, "selection": "Full autosomal/X/Y ranked peaks of biological replicates 1 and 2; protein-coding gene TSSs",
                "scale": json.loads((output / "dimensions.json").read_text()),
                "input_bytes": data.stat().st_size,
                "input_sha256": hashlib.file_digest(data.open("rb"), "sha256").hexdigest()}
    (output / "dataset.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"task": "T06", "input": str(data), "bytes": data.stat().st_size}))


if __name__ == "__main__":
    main()
