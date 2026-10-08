#!/usr/bin/env bash
# Re-fetch the pages in tools/docs_pages.txt and rebuild docs/cc/. Run from the repo root.
set -euo pipefail
raw=$(mktemp -d)
grep -v '^#' tools/docs_pages.txt | while read -r p; do
  [ -z "$p" ] && continue
  code=$(curl -sSL -o "$raw/$p.md" -w '%{http_code}' "https://code.claude.com/docs/en/$p.md")
  [ "$code" = 200 ] || { echo "FAIL $p HTTP $code" >&2; exit 1; }
done
python3 -I tools/docs_split.py "$raw" docs/cc "$(date -u +%F)"
rm -rf "$raw"
echo "Done. Review: git diff --stat docs/cc"
