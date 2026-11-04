# T01 input and collection support

These files directly supported the final dev.20 T01 A1/C1 comparison:

- `prepare-screen.py`: prepare a larger, stratified set of genuine cells.
- `read-screen.py` and `read-probe.R`: compare byte-identical uncompressed and
  standard gzip representations; measure three fresh-process reads and hashes.
- `storage-pilot.py`: SHA/source inventory, native evidence capture and memory
  supervision helpers imported by the final confirmation controller.

The historical directory and helper filename remain compatible with the
recorded controller imports. There is no longer a multi-storage pilot CLI or
an alternative concise/matrix workload generator. The final comparison uses
one gzip input and two arms; it is not an ablation experiment.

The selected input contains 450,000 real GSE236581 cells and 36,027 genes.
Its three gzip reads took 23.569, 23.584 and 23.561 seconds; OS caches were not
cleared. No observations were replicated and no artificial delay was added.
Memory gates were 12GiB available before launch, 11GiB sampled process-tree
RSS and 3GiB minimum available RAM. Both arms used `R_MAX_VSIZE=10G`.

See [the runbook](../../RUNBOOK.md) for the execution condition and
[the public result](../../../docs/REPORT-T01-live.en.md) for scope and hashes.
Original controllers, failed candidates, cancelled runs and exact source
archives stay under the local ignored runs directory at their original paths.
