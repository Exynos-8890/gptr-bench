# Real-data source review for Benchmark 1 revision 0.3

Reviewed: 2026-10-28. This source investigation preceded the implementation. The extension is now completed in [the v0.3 real-data report](results/report.md).

## Reference benchmark and access

The supplied DOI identifies *BiomniBench: Process-level Evaluation of LLM Agents for Real-world Biomedical Research*. The [requested v1 page](https://www.biorxiv.org/content/10.64898/2026.05.12.724604v1) could be identified in search but returned HTTP 403 when opened. The search-readable [v2 full text](https://www.biorxiv.org/content/10.64898/2026.05.12.724604v2.full) explicitly includes a colorectal-cancer single-cell task using GEO GSE236581. Do not attribute unverified v2 details specifically to v1.

The authors' [Hugging Face dataset card](https://huggingface.co/datasets/phylobio/BiomniBench-DA) currently releases 50 of 100 tasks and reports 82.9 GB total files. File access requires login and acceptance of information-sharing conditions. Benchmark instructions, rubrics, reference traces and judge prompts are CC-BY-4.0; underlying datasets retain their own terms. Direct GEO access therefore avoids depending on access to the benchmark bundle. No restricted files or account conditions were accessed or accepted.

## Recommended real dataset

The original [Cancer Cell publication](https://www.cell.com/article/S1535610824002344/pdf), *Spatiotemporal single-cell analysis decodes cellular dynamics underlying different responses to immunotherapy in colorectal cancer*, reports 22 patients, 169 samples and 975,275 quality-controlled single cells. Its availability statement points to processed data under [GEO GSE236581](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE236581), raw FASTQ under GSA PRJCA018173, and analysis code in [yqq-chen/CRC_ICB](https://github.com/yqq-chen/CRC_ICB). This is a real longitudinal immune-oncology dataset, rather than a simulated cohort. Use the processed expression matrix for the proposed benchmark; raw sequencing is unnecessary.

The [GEO supplementary directory](https://ftp.ncbi.nlm.nih.gov/geo/series/GSE236nnn/GSE236581/suppl/) publishes these files:

| File | Approximate compressed size in GEO | Purpose |
|---|---:|---|
| `GSE236581_counts.mtx.gz` | 3.9 GB | Gene-by-cell UMI counts |
| `GSE236581_barcodes.tsv.gz` | 4.5 MB | Cell identifiers |
| `GSE236581_features.tsv.gz` | 243.5 KB | Gene identifiers and symbols |
| `GSE236581_CRC-ICB_metadata.txt.gz` | 12.7 MB | Cell, patient, tissue and time annotations |

The matrix and metadata headers were inspected directly through short HTTPS streams, without downloading the complete files. The matrix header reports **36,027 genes × 975,275 cells and 1,310,816,895 nonzero entries**. Metadata columns are `orig.ident`, `nCount_RNA`, `nFeature_RNA`, `Ident`, `Patient`, `Treatment`, `Tissue`, `MajorCellType`, and `SubCellType`. Patient/tissue/treatment summaries can therefore be defined without the benchmark bundle's `clinical.xlsx`. Response labels are absent from this metadata header; a response-stratified task would need a separately verified clinical source.

The GEO series record lists its last update as 2024-07-29; record that date alongside downloaded-file checksums when freezing the input. We are borrowing the paper's use of real study data and traceable analysis, not importing its full benchmark or judge framework. The direct GEO files are sufficient for the proposed task, and Hugging Face access is optional.

Public availability is confirmed; an explicit permissive redistribution license for the underlying patient dataset was not established. Preserve source attribution and verify applicable release terms before redistributing copies. The author's GitHub README states all rights reserved; reference code is not automatically available for unrestricted copying.

## Proposed adaptation and feasibility

Keep the five existing execution arms, but introduce a single-cell task: calculate QC metrics from counts, aggregate expression by sample and annotated group, then change a QC threshold and recompute the affected summaries. These operations must consume the expression matrix, not just the small metadata table. The current survival analysis remains a functional check; synthetic data does not establish real large-data performance.

The complete matrix is substantial. A rough in-memory sparse representation with 8-byte values and 4-byte row indices needs about 15.7 GB for nonzero arrays alone, excluding pointers, temporary conversion buffers and copies. This is an estimate, not a measurement. Preflight memory, test a fixed real-cell subset, preserve sparsity, and run the full tier only on a sufficiently provisioned host. Avoid dense conversion. Pin dataset checksums, subset identifiers, R/package versions, model and source revision. Keep download/preparation outside task timing and initial loading inside it, matching the existing measurement convention. Validate deterministic output tables before converting real trajectories to fake-provider replay input.

## Verification log

- bioRxiv v1/v2 direct access: HTTP 403; search index provides identification and v2 task excerpt.
- Authors' Hugging Face card: read publicly; access gate and terms explicitly observed.
- GEO series search record: processed-file sizes, study summary and public status checked.
- NCBI HTTPS directory: listing inspected directly; matrix and metadata first lines streamed and connection closed.
- Original paper and authors' repository: data availability and code-rights statement checked.
- Implemented evidence: complete source SHA-256 and 100,000-cell preparation, per-cell annotation matching, a clean byte-identical preparation rerun, all 66 formal executions valid, and separately versioned native-helper capture repair. See the v0.3 report.
- Not measured: full 975,275-cell tier (host capacity gate). Clinical response labels are not needed by the implemented QC/expression task.
