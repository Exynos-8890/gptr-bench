#!/usr/bin/env bash
set -e
bench_repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$bench_repo_root"
exec env PATH="$bench_repo_root/.runtime/codex/node_modules/.bin:$bench_repo_root/.runtime/venv/bin:$PATH" \
  R_LIBS_USER="$bench_repo_root/.runtime/library${R_LIBS_USER:+:$R_LIBS_USER}" \
  OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 "$@"
