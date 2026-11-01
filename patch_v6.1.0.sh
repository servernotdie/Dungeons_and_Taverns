#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZIP_FILE="$1"
OUT_DIR="${2:-out}"

if [ -z "$ZIP_FILE" ]; then
    echo "Usage: $0 <dungeons-and-taverns-v6.1.0.zip> [output-dir]"
    exit 1
fi

if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: File not found: $ZIP_FILE"
    exit 1
fi

WORK_DIR=$(mktemp -d /tmp/datapack_patch_v6_XXXXXX)
trap "rm -rf $WORK_DIR" EXIT

echo "Extracting $ZIP_FILE..."
unzip -q "$ZIP_FILE" -d "$WORK_DIR/datapack"

# Convert CRLF to LF in all mcfunction and json files
echo "Normalizing line endings..."
find "$WORK_DIR/datapack" \( -name '*.mcfunction' -o -name '*.json' \) -exec sed -i 's/\r$//' {} \;

echo "Applying v6.1.0 Folia patch..."
patch -Nt -p0 -d "$WORK_DIR/datapack" < "$SCRIPT_DIR/Dungeons_and_Taverns_v6.1.0_folia_Fix.patch" || true

# Fix hydro_veil_heal manually
echo "Fixing hydro_veil_heal.mcfunction..."
HYDRO_FILE="$WORK_DIR/datapack/data/nova_structures/function/enchantment/hydro_veil_heal.mcfunction"
if [ -f "$HYDRO_FILE" ]; then
    cat > "$HYDRO_FILE" << 'HYDRO'
particle minecraft:splash ~ ~2 ~ 0.8 0.8 0.8 0 25 normal
playsound minecraft:ambient.underwater.loop.additions neutral @a ~ ~ ~ 0.1 2
effect give @s minecraft:regeneration 1 6 true
HYDRO
fi

# Fix spawn_chicken_jockey_zombie manually
echo "Fixing spawn_chicken_jockey_zombie.mcfunction..."
JOCKEY_FILE="$WORK_DIR/datapack/data/nova_structures/function/jockey/spawn_chicken_jockey_zombie.mcfunction"
if [ -f "$JOCKEY_FILE" ]; then
    cat > "$JOCKEY_FILE" << 'JOCKEY'
attribute @s minecraft:spawn_reinforcements modifier add minecraft:leader_zombie_bonus 0.625 add_value
attribute @s minecraft:max_health modifier add minecraft:leader_zombie_bonus 2.5 add_multiplied_total
attribute @s minecraft:max_health base set 50
JOCKEY
fi

# Remove ghast_boss_fireball_possess
echo "Removing ghast_boss_fireball_possess.mcfunction..."
rm -f "$WORK_DIR/datapack/data/nova_structures/function/miniboss/ghast_boss_fireball_possess.mcfunction"

# Remove .rej files from failed patches
find "$WORK_DIR/datapack" -name '*.rej' -delete 2>/dev/null || true

# Remove .orig backup files
find "$WORK_DIR/datapack" -name '*.orig' -delete 2>/dev/null || true

mkdir -p "$OUT_DIR"
OUTPUT="$(cd "$OUT_DIR" && pwd)/Dungeons_and_Taverns_v6.1.0_folia.zip"

rm -f "$OUTPUT"
cd "$WORK_DIR/datapack"
zip -r -q "$OUTPUT" .

echo "Done! Output: $OUTPUT"
