#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Encrypt & deploy to GitHub Pages
#
# Usage:
#   ./deploy.sh <report-slug> /path/to/report.html
#
# Examples:
#   ./deploy.sh ddr-vs-msi /path/.../report_x.html
#   ./deploy.sh mmr-expr   /path/.../another_report.html
#
# The script always re-encrypts the landing page (index.html) AND the
# specified report (reports/<slug>/index.html) with the same password
# and salt, so the "Remember me" feature works across all pages.
#
# First-time setup (one-off):
#   chmod +x deploy.sh
#   GitHub → repo → Settings → Pages → Branch: main / folder: / (root)
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SALT_FILE="$REPO_DIR/.staticrypt-salt"
SRC_INDEX="$REPO_DIR/_src/index.html"

SLUG="${1:-}"
HTML_SRC="${2:-}"

# ── Argument check ────────────────────────────────────────────────────────────
if [[ -z "$SLUG" || -z "$HTML_SRC" ]]; then
  echo "Usage: ./deploy.sh <report-slug> /path/to/report.html"
  echo ""
  echo "Example:"
  echo "  ./deploy.sh ddr-vs-msi /path/to/report_x.html"
  exit 1
fi

if [[ ! -f "$HTML_SRC" ]]; then
  echo "Error: report file not found: $HTML_SRC"
  exit 1
fi

if [[ ! -f "$SRC_INDEX" ]]; then
  echo "Error: landing page source not found: $SRC_INDEX"
  exit 1
fi

if [[ ! -f "$SALT_FILE" ]]; then
  echo "Error: salt file not found: $SALT_FILE"
  exit 1
fi

SALT=$(cat "$SALT_FILE")

# ── Password prompt (not echoed, never stored) ────────────────────────────────
echo ""
read -rsp "🔑  Enter page password (not echoed): " PASSWORD
echo ""
read -rsp "🔑  Confirm password: " PASSWORD2
echo ""

if [[ "$PASSWORD" != "$PASSWORD2" ]]; then
  echo "Error: passwords do not match."
  exit 1
fi

if [[ ${#PASSWORD} -lt 6 ]]; then
  echo "Error: password must be at least 6 characters."
  exit 1
fi

# ── Helper: encrypt one HTML file ────────────────────────────────────────────
# Usage: encrypt_to <source.html> <output_dir>
# staticrypt v3 names the output after the input, so we stage via a temp
# file called "index.html" to always produce <output_dir>/index.html
encrypt_to() {
  local src="$1"
  local out_dir="$2"
  local tmp
  tmp=$(mktemp -d)
  cp "$src" "$tmp/index.html"
  mkdir -p "$out_dir"
  npx --yes staticrypt "$tmp/index.html" \
    --password "$PASSWORD" \
    --salt     "$SALT" \
    -d         "$out_dir" \
    --short \
    --remember 7 \
    --template-color-primary   "#047857" \
    --template-color-secondary "#f0fdf4" \
    --template-button "Unlock"
  rm -rf "$tmp"
}

# ── Encrypt landing page → index.html ────────────────────────────────────────
echo ""
echo "Encrypting landing page..."
encrypt_to "$SRC_INDEX" "$REPO_DIR"
echo "✓  index.html"

# ── Encrypt report → reports/<slug>/index.html ───────────────────────────────
REPORT_DIR="$REPO_DIR/reports/$SLUG"
echo "Encrypting report '$SLUG'..."
encrypt_to "$HTML_SRC" "$REPORT_DIR"
echo "✓  reports/$SLUG/index.html"

unset PASSWORD PASSWORD2

# ── Commit & push ─────────────────────────────────────────────────────────────
cd "$REPO_DIR"
git add index.html "reports/$SLUG/index.html"
git diff --cached --quiet && echo "" && echo "No changes to commit." && exit 0

STAMP=$(date '+%Y-%m-%d %H:%M')
git commit -m "Deploy: $SLUG ($STAMP)"
git push origin main

echo ""
echo "✓  Deployed to:"
echo "   https://ckntav.github.io/20260227_test_encrypt_dataviz/"
