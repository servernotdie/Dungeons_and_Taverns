#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZIP_FILE="$1"
OUT_DIR="${2:-out}"

if [ -z "$ZIP_FILE" ]; then
    echo "Usage: $0 <dungeons-and-taverns.zip> [output-dir]"
    exit 1
fi

if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: File not found: $ZIP_FILE"
    exit 1
fi

WORK_DIR=$(mktemp -d /tmp/datapack_patch_XXXXXX)
trap "rm -rf $WORK_DIR" EXIT

echo "Extracting $ZIP_FILE..."
unzip -q "$ZIP_FILE" -d "$WORK_DIR/datapack"

# Convert CRLF to LF in all mcfunction files to avoid patch issues
echo "Normalizing line endings..."
find "$WORK_DIR/datapack" -name '*.mcfunction' -exec sed -i 's/\r$//' {} \;

echo "Applying patch..."
# -N: skip already applied (avoid reversed)
# -t: batch mode (don't ask questions)
patch -Nt -p1 -d "$WORK_DIR/datapack" < "$SCRIPT_DIR/Dungeons_and_Taverns_Folia_Fix.patch" || true

mkdir -p "$OUT_DIR"
OUTPUT="$(cd "$OUT_DIR" && pwd)/Dungeons_and_Taverns_v5.2.0_folia.zip"

cd "$WORK_DIR/datapack"
zip -r -q "$OUTPUT" .

echo "Done! Output: $OUTPUT"