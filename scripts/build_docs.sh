#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/docs"

mkdir -p "${OUT_DIR}"
bend "${ROOT_DIR}/src/main.bend" --to-web --no-strict > "${OUT_DIR}/index.html"
mkdir -p "${OUT_DIR}/assets"
cp -R "${ROOT_DIR}/assets/." "${OUT_DIR}/assets"

echo "Built deployable site in ${OUT_DIR}"
