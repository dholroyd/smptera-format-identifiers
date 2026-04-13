#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SMPTE_PAGE="https://smpte-ra.org/registered-mpeg-ts-ids"
OUTPUT="$SCRIPT_DIR/Public.csv"

# Scrape the SMPTE page to find the Zoho Creator iframe URL
echo "Fetching $SMPTE_PAGE ..."
iframe_url=$(curl -sL "$SMPTE_PAGE" \
  | grep -oP 'src="https://creator\.zohopublic\.com/[^"]+/view-embed/[^"]+"' \
  | head -1 \
  | sed 's/^src="//; s/"$//')

if [ -z "$iframe_url" ]; then
  echo "Error: could not find Zoho iframe URL on the SMPTE page." >&2
  exit 1
fi

# Convert the view-embed URL to a CSV download URL
csv_url="${iframe_url/view-embed/csv}"

echo "Downloading CSV from $csv_url ..."
content_type=$(curl -sL "$csv_url" -o "$OUTPUT" -w '%{content_type}')

if [[ "$content_type" != text/csv* ]]; then
  echo "Error: expected text/csv but got '$content_type'." >&2
  exit 1
fi

# Sanity check: file should have a header and at least one data row
line_count=$(wc -l < "$OUTPUT")
if [ "$line_count" -lt 2 ]; then
  echo "Error: downloaded file has only $line_count line(s) — expected CSV data." >&2
  exit 1
fi

echo "Updated $OUTPUT ($line_count lines)"
