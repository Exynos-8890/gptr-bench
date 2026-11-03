#!/usr/bin/env bash
set -e
bench_repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$bench_repo_root"
sudo apt-get update
sudo apt-get install -y r-base r-base-dev build-essential gfortran \
  libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev libfontconfig1-dev \
  libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff-dev libjpeg-dev \
  python3 python3-venv nodejs npm git curl ca-certificates
mkdir -p .runtime/library
python3 -m venv .runtime/venv
.runtime/venv/bin/python -m pip install psutil
npm install --prefix .runtime/codex @openai/codex@0.165.0
R_LIBS_USER="$bench_repo_root/.runtime/library" Rscript --vanilla \
  biomedical/v0.5/aws/shared/setup-v04.R --install
