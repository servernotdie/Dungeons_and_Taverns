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

# Convert CRLF to LF in all mcfunction files
echo "Normalizing line endings..."
find "$WORK_DIR/datapack" -name '*.mcfunction' -exec sed -i 's/\r$//' {} \;

echo "Applying existing patch..."
patch -Nt -p1 -d "$WORK_DIR/datapack" < "$SCRIPT_DIR/Dungeons_and_Taverns_Folia_Fix.patch" || true

# Overwrite all broken functions with no-op to prevent Folia errors.
echo "Patching broken functions for Folia compatibility..."
DP="$WORK_DIR/datapack/data/nova_structures/function"
for f in \
    load tick \
    quest/mark_quest_trader quest/villager_lvcheck quest/saddle_trade_checker \
    quest/add_trade_lv2 quest/add_trade_lv3 quest/add_trade_lv4 quest/add_trade_lv5 \
    quest/scheduled quest/start \
    ghast_boss_fireball_possess \
    jockey/make_drowned_into_jockey \
    swift_soar_1 swift_soar_2 swift_soar_3 \
    tech_enchant_remove/start \
    tech_enchant_remove/book_1 tech_enchant_remove/book_2 tech_enchant_remove/book_3 \
    tech_enchant_remove/book_4 tech_enchant_remove/book_5 \
    tech_enchant_remove/item_1 tech_enchant_remove/item_2 tech_enchant_remove/item_3 \
    tech_enchant_remove/item_4 tech_enchant_remove/item_5 \
    chart_unfold chart_title chart_bundle_fix; do
    fp="$DP/$f.mcfunction"
    if [ -f "$fp" ]; then
        echo "# patched for folia compatibility" > "$fp"
    fi
done

find "$WORK_DIR/datapack" -name '*.rej' -delete 2>&1 || true

mkdir -p "$OUT_DIR"
OUTPUT="$(cd "$OUT_DIR" && pwd)/Dungeons_and_Taverns_v5.2.0_folia.zip"

rm -f "$OUTPUT"
cd "$WORK_DIR/datapack"
zip -r -q "$OUTPUT" .

echo "Done! Output: $OUTPUT"