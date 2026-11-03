"""Download open GDC TCGA-LUAD STAR counts and prepare the full tumor/normal cohort."""

import argparse
import csv
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import subprocess
import time
import urllib.parse
import urllib.request


def download(url, path, expected_md5=None):
    if not path.exists():
        temporary = path.with_suffix(path.suffix + ".part")
        request = urllib.request.Request(url, headers={"User-Agent": "gptr-biomedical-benchmark/0.4"})
        with urllib.request.urlopen(request, timeout=180) as response, temporary.open("wb") as out:
            while block := response.read(1 << 20):
                out.write(block)
        temporary.replace(path)
    if expected_md5:
        with path.open("rb") as handle:
            if hashlib.file_digest(handle, "md5").hexdigest() != expected_md5:
                raise ValueError(f"GDC checksum mismatch: {path.name}")
    with path.open("rb") as handle:
        digest = hashlib.file_digest(handle, "sha256").hexdigest()
    return {"url": url, "file": path.name, "bytes": path.stat().st_size, "sha256": digest,
            "source_md5": expected_md5}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--workers", type=int, default=4)
    args = parser.parse_args()
    source, output = args.source_dir.resolve(), args.output_dir.resolve()
    source.mkdir(parents=True, exist_ok=True)
    output.mkdir(parents=True, exist_ok=True)
    filters = {"op": "and", "content": [
        {"op": "=", "content": {"field": "cases.project.project_id", "value": "TCGA-LUAD"}},
        {"op": "=", "content": {"field": "analysis.workflow_type", "value": "STAR - Counts"}},
        {"op": "=", "content": {"field": "access", "value": "open"}},
    ]}
    fields = "file_id,file_name,md5sum,file_size,cases.submitter_id,cases.samples.submitter_id,cases.samples.sample_type"
    url = "https://api.gdc.cancer.gov/files?" + urllib.parse.urlencode({
        "filters": json.dumps(filters), "fields": fields, "size": 2000})
    metadata = source / "gdc-files.json"
    sources = [download(url, metadata)]
    response = json.loads(metadata.read_text())
    if response["data"]["pagination"]["total"] > 2000:
        raise ValueError("GDC query truncated; extend pagination before preparation")
    candidates = {}
    for file in sorted(response["data"]["hits"], key=lambda f: f["file_id"]):
        if len(file.get("cases", [])) != 1:
            continue
        case = file["cases"][0]
        eligible = [s for s in case.get("samples", [])
                    if s.get("sample_type") in {"Primary Tumor", "Solid Tissue Normal"}]
        if len(eligible) != 1:
            continue
        sample = eligible[0]
        key = (case["submitter_id"], sample["sample_type"])
        if key in candidates:
            continue
        candidates[key] = {"sample": sample["submitter_id"], "patient": case["submitter_id"],
                           "group": "Tumor" if sample["sample_type"] == "Primary Tumor" else "Normal",
                           "batch": case["submitter_id"].split("-")[1], "file_id": file["file_id"],
                           "md5": file["md5sum"]}
    rows = sorted(candidates.values(), key=lambda r: r["sample"])
    if len(rows) < 100 or len({r["patient"] for r in rows if r["group"] == "Normal"}) < 10:
        raise ValueError("Expected full LUAD cohort not found; inspect metadata rather than use a small stand-in")
    def fetch(row):
        return download("https://api.gdc.cancer.gov/data/" + row["file_id"],
                        source / (row["file_id"] + ".tsv"), row["md5"])
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        sources.extend(pool.map(fetch, rows))
    reactome = source / "Ensembl2Reactome.txt"
    sources.append(download("https://reactome.org/download/current/Ensembl2Reactome.txt", reactome))
    with (output / "samples.tsv").open("w") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)
    code = """
      a=commandArgs(TRUE); src=a[1]; out=a[2]
      samples=utils::read.delim(file.path(out,'samples.tsv'),stringsAsFactors=FALSE)
      tables=lapply(samples$file_id,function(id) {
        x=utils::read.delim(file.path(src,paste0(id,'.tsv')),comment.char='#',
          check.names=FALSE,stringsAsFactors=FALSE)
        x=x[startsWith(x$gene_id,'ENSG'),c('gene_id','gene_name','unstranded')]
        stopifnot(nrow(x)>50000,all(x$unstranded>=0)); x
      })
      stopifnot(all(vapply(tables,function(x) identical(x$gene_id,tables[[1]]$gene_id),logical(1))))
      counts=vapply(tables,function(x) as.integer(x$unstranded),integer(nrow(tables[[1]])))
      rownames(counts)=sub('[.][0-9]+','',tables[[1]]$gene_id); colnames(counts)=samples$sample
      stopifnot(!anyDuplicated(rownames(counts)),!anyDuplicated(colnames(counts)))
      mapping=utils::read.delim(file.path(src,'Ensembl2Reactome.txt'),header=FALSE,
        quote='',stringsAsFactors=FALSE,col.names=c('gene','pathway','url','name','evidence','species'))
      mapping=mapping[mapping$species=='Homo sapiens' & mapping$gene %in% rownames(counts),]
      pathways=lapply(split(mapping$gene,paste(mapping$pathway,mapping$name,sep=':')),unique)
      pathways=pathways[lengths(pathways)>=10 & lengths(pathways)<=500]
      raw=list(counts=counts,samples=samples[c('sample','patient','group','batch')],pathways=pathways,
        features=data.frame(gene=rownames(counts),symbol=tables[[1]]$gene_name))
      saveRDS(raw,file.path(out,'input.rds'),compress=FALSE)
      jsonlite::write_json(list(genes=nrow(counts),samples=ncol(counts),
        groups=as.list(table(samples$group)),pathways=length(pathways)),
        file.path(out,'dimensions.json'),auto_unbox=TRUE)
    """
    subprocess.run(["Rscript", "--vanilla", "-e", code, str(source), str(output)], check=True)
    input_path = output / "input.rds"
    manifest = {"synthetic": False, "fully_resident": True, "task": "T03", "prepared_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "source": "GDC open TCGA-LUAD STAR - Counts; Reactome human pathways",
                "selection": "All primary tumor/solid tissue normal patients; one lexicographically first file UUID per patient and tissue group; exclude ambiguous file/sample links",
                "batch": "TCGA tissue source site from patient barcode", "sources": sources,
                "scale": json.loads((output / "dimensions.json").read_text()),
                "input_bytes": input_path.stat().st_size,
                "input_sha256": hashlib.file_digest(input_path.open("rb"), "sha256").hexdigest()}
    (output / "dataset.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"task": "T03", "input": str(input_path), "bytes": input_path.stat().st_size}))


if __name__ == "__main__":
    main()
