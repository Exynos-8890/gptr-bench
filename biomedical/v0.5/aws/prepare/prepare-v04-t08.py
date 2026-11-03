"""Prepare PDC000173 log2-ratio protein data with real iTRAQ and PAM50 mappings."""

import argparse
import csv
import gzip
import hashlib
import io
import json
from pathlib import Path
import subprocess
import time
import urllib.parse
import urllib.request


def download(url, path):
    if not path.exists():
        temporary = path.with_suffix(path.suffix + ".part")
        with urllib.request.urlopen(url, timeout=180) as response, temporary.open("wb") as out:
            while block := response.read(1 << 20):
                out.write(block)
        temporary.replace(path)
    with path.open("rb") as handle:
        digest = hashlib.file_digest(handle, "sha256").hexdigest()
    return {"url": url, "file": path.name, "bytes": path.stat().st_size, "sha256": digest}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--accept-pdc-dua", action="store_true",
                        help="Use only after the data-use agreement has been reviewed and explicitly authorized")
    args = parser.parse_args()
    source, output = args.source_dir.resolve(), args.output_dir.resolve()
    source.mkdir(parents=True, exist_ok=True)
    output.mkdir(parents=True, exist_ok=True)
    sources = []
    def query(name, text):
        url = "https://pdc.cancer.gov/graphql?" + urllib.parse.urlencode({"query": text})
        path = source / (name + ".json")
        sources.append(download(url, path))
        response = json.loads(path.read_text())
        if response.get("errors"):
            raise ValueError("PDC refused query; inspect response. No DUA is accepted by default.")
        return response["data"]
    biospecimen = query("biospecimen", '{ biospecimenPerStudy(pdc_study_id:"PDC000173") '
                         '{ aliquot_id aliquot_submitter_id case_submitter_id sample_submitter_id } }')
    design = query("experimental-design", '{ studyExperimentalDesign(pdc_study_id:"PDC000173") '
                   '{ plex_dataset_name itraq_114 {aliquot_id aliquot_submitter_id} '
                   'itraq_115 {aliquot_id aliquot_submitter_id} itraq_116 {aliquot_id aliquot_submitter_id} '
                   'itraq_117 {aliquot_id aliquot_submitter_id} } }')
    accept = " acceptDUA:true" if args.accept_pdc_dua else ""
    quantitative = query("log2-ratio", '{ quantDataMatrix(pdc_study_id:"PDC000173" '
                         'data_type:"log2_ratio"' + accept + ') }')
    matrix = quantitative["quantDataMatrix"]
    if not matrix or not isinstance(matrix[0], list) or len(matrix) < 1000:
        raise ValueError("Unexpected PDC quantitation format or unavailable data-use permission")
    clinical = source / "tcga-brca-clinical.txt"
    sources.append(download("https://media.githubusercontent.com/media/cBioPortal/datahub/master/public/"
                            "brca_tcga_pan_can_atlas_2018/data_clinical_patient.txt", clinical))
    clinical_text = "\n".join(line for line in clinical.read_text().splitlines()
                              if not line.startswith("#"))
    metadata = list(csv.DictReader(io.StringIO(clinical_text), delimiter="\t"))
    subtype = {row["PATIENT_ID"]: row["SUBTYPE"].removeprefix("BRCA_") for row in metadata}
    aliquots = biospecimen["biospecimenPerStudy"]
    lookup = {row[key]: row for row in aliquots for key in ["aliquot_id", "aliquot_submitter_id"]}
    batch = {}
    for plex in design["studyExperimentalDesign"]:
        for channel in ["itraq_114", "itraq_115", "itraq_116", "itraq_117"]:
            for aliquot in plex.get(channel) or []:
                for key in ["aliquot_id", "aliquot_submitter_id"]:
                    value = aliquot[key]
                    mapping = (plex["plex_dataset_name"], channel)
                    if value in batch and batch[value] != mapping and "Reference" not in value:
                        raise ValueError("Aliquot occurs in multiple plexes: preserve technical runs before preparation")
                    batch[value] = mapping
    samples = []
    for name in matrix[0][1:]:
        if name not in lookup or name not in batch:
            raise ValueError("Unmapped PDC matrix aliquot; no patient, batch or channel is inferred")
        row = lookup[name]
        samples.append({"sample": name, "patient": row["case_submitter_id"],
                        "subtype": subtype.get(row["case_submitter_id"], ""),
                        "batch": batch[name][0], "channel": batch[name][1],
                        "is_reference": batch[name][1] == "itraq_117"})
    with (output / "samples.tsv").open("w") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(samples[0]), delimiter="\t")
        writer.writeheader()
        writer.writerows(samples)
    with (output / "abundance.tsv").open("w") as handle:
        csv.writer(handle, delimiter="\t").writerows(matrix)
    mapping = source / "NCBI2Reactome.txt"
    sources.append(download("https://reactome.org/download/current/NCBI2Reactome.txt", mapping))
    gene_info = source / "Homo_sapiens.gene_info.gz"
    sources.append(download("https://ftp.ncbi.nlm.nih.gov/gene/DATA/GENE_INFO/Mammalia/"
                            "Homo_sapiens.gene_info.gz", gene_info))
    with gzip.open(gene_info, "rt") as handle:
        symbols = {row["GeneID"]: row["Symbol"] for row in csv.DictReader(handle, delimiter="\t")}
    sets = {}
    with mapping.open() as handle:
        for row in csv.reader(handle, delimiter="\t"):
            if row[5] == "Homo sapiens" and row[0] in symbols:
                sets.setdefault(row[1] + ":" + row[3], set()).add(symbols[row[0]])
    (output / "pathways.json").write_text(json.dumps({k: sorted(v) for k, v in sets.items() if 10 <= len(v) <= 500}))
    code = """
      a=commandArgs(TRUE); out=a[1]
      table=utils::read.delim(file.path(out,'abundance.tsv'),check.names=FALSE,
        stringsAsFactors=FALSE,na.strings=c('NA','NaN','','null'))
      x=as.matrix(table[,-1,drop=FALSE]); storage.mode(x)='double'; rownames(x)=table[[1]]
      samples=utils::read.delim(file.path(out,'samples.tsv'),stringsAsFactors=FALSE)
      samples$is_reference=tolower(samples$is_reference)=='true'
      stopifnot(identical(colnames(x),samples$sample),!anyDuplicated(rownames(x)))
      pathways=jsonlite::read_json(file.path(out,'pathways.json'),simplifyVector=TRUE)
      pathways=lapply(pathways,intersect,rownames(x)); pathways=pathways[lengths(pathways)>=10]
      stopifnot(length(pathways)>0,ncol(x)>80,nrow(x)>1000)
      raw=list(abundance=x,samples=samples,pathways=pathways,scale='log2_ratio_to_reference')
      saveRDS(raw,file.path(out,'input.rds'),compress=FALSE)
      jsonlite::write_json(list(proteins=nrow(x),aliquots=ncol(x),
        known_subtype=sum(nzchar(samples$subtype)),pathways=length(pathways)),
        file.path(out,'dimensions.json'),auto_unbox=TRUE)
    """
    subprocess.run(["Rscript", "--vanilla", "-e", code, str(output)], check=True)
    data = output / "input.rds"
    manifest = {"synthetic": False, "fully_resident": True, "task": "T08", "prepared_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "source": "PDC000173 CDAP log2_ratio; TCGA PanCancer Atlas PAM50; Reactome",
                "sources": sources, "scale": json.loads((output / "dimensions.json").read_text()),
                "quantitative_scale": "log2 ratio to pooled iTRAQ reference; no additional log transform",
                "dua_accepted_by_explicit_flag": args.accept_pdc_dua,
                "input_bytes": data.stat().st_size,
                "input_sha256": hashlib.file_digest(data.open("rb"), "sha256").hexdigest()}
    (output / "dataset.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"task": "T08", "input": str(data), "bytes": data.stat().st_size}))


if __name__ == "__main__":
    main()
