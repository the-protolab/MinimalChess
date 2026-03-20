#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/.preview"
PORT="${1:-61424}"

mkdir -p "${OUT_DIR}"
bend "${ROOT_DIR}/src/main.bend" --to-web --no-strict > "${OUT_DIR}/index.html"
rm -rf "${OUT_DIR}/assets"
cp -R "${ROOT_DIR}/assets" "${OUT_DIR}/assets"

echo "Serving Minimal Chess preview on http://127.0.0.1:${PORT}"
cd "${OUT_DIR}"
python3 -m http.server "${PORT}"
