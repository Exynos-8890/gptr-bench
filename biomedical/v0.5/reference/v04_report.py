"""Build timelines exclusively from recorded timestamps; never impute model thinking time."""
import csv
import json
from pathlib import Path
import subprocess


def timeline_rows(row):
    directory = Path(row["record_directory"])
    origin = row["run_started_unix"]
    spans = []
    def add(kind, label, request, start, end):
        if end >= start:
            spans.append(dict(kind=kind, label=label, request=request,
                              start_s=start-origin, end_s=end-origin, duration_s=end-start))
    io_path = directory / "io.jsonl"
    if io_path.exists():
        for event in map(json.loads, io_path.read_text().splitlines()):
            kind = "Rscript" if event["operation"] == "rscript" else "RDS"
            add(kind, event["operation"] + " " + Path(event["file"]).name,
                event["request"], event["started_unix"], event["finished_unix"])
    trace_path = directory / "trace.jsonl"
    events = list(map(json.loads, trace_path.read_text().splitlines())) if trace_path.exists() else []
    anchor = next((event["data"]["unix"] - event["time_ms"] / 1000 for event in events
                   if event["type"] == "request_start"), None)
    pending = {}
    for event in events:
        kind = event["type"]
        data = event.get("data", {})
        request = event.get("request", event.get("turn", 0))
        if kind in {"request_start", "request_end"}:
            key = ("request", request)
            if kind.endswith("start"):
                pending[key] = data["unix"]
            elif key in pending:
                add("Request", f"Q{request}", request, pending.pop(key), data["unix"])
        elif kind in {"tool_execution_start", "tool_execution_end"} and anchor is not None:
            key = ("tool", data["tool_call_id"])
            timestamp = anchor + event["time_ms"] / 1000
            if kind.endswith("start"):
                pending[key] = timestamp
            elif key in pending:
                add("Tool", data.get("tool_name", "tool"), request, pending.pop(key), timestamp)
        elif kind in {"canonical_step_start", "canonical_step_end"}:
            key = ("canonical", event["pid"], event["step"])
            if kind.endswith("start"):
                pending[key] = event["unix"]
            elif key in pending:
                add("Tool", f"block {event['step']}", request, pending.pop(key), event["unix"])
        elif kind in {"item.started", "item.completed"} and anchor is not None:
            item = data.get("item", {})
            if item.get("type") != "command_execution":
                continue
            key = ("command", item["id"], request)
            timestamp = anchor + event["time_ms"] / 1000
            if kind.endswith("started"):
                pending[key] = timestamp
            elif key in pending:
                add("Tool", "CLI command", request, pending.pop(key), timestamp)
    # Unmatched spans are omitted and explicitly reported, never given invented endpoints.
    return sorted(spans, key=lambda span: span["start_s"]), len(pending)


def timelines(rows):
    plotter = Path(__file__).with_name("plot-v04-timeline.R")
    for row in rows:
        spans, incomplete = timeline_rows(row)
        directory = Path(row["record_directory"])
        with (directory / "timeline.csv").open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=["kind", "label", "request", "start_s", "end_s", "duration_s"])
            writer.writeheader()
            writer.writerows(spans)
        (directory / "timeline-notes.json").write_text(json.dumps(dict(
            incomplete_spans_omitted=incomplete,
            notice="Request, tool and RDS spans overlap. Gaps are not pure model thinking. "
                   "RDS includes serialization/deserialization, not measured physical disk IO."), indent=2))
        if spans:
            subprocess.run(["Rscript", "--vanilla", str(plotter), str(directory / "timeline.csv"),
                            str(directory / "timeline.png")], check=True, capture_output=True)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("results", type=Path)
    args = parser.parse_args()
    timelines(json.loads(args.results.read_text()))
