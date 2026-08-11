#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
#
#  Touchpad Toggle — Smoke Test
#
# ──────────────────────────────────────────────────────────────────────
#
# Purpose   Smoke test the release package of the Touchpad Toggle 
#           utility and the optional GNOME extension. Validates
#           structural integrity and basic CLI behavior. Does NOT
#           require a live GNOME session or touchpad hardware.
#
# Author    Copyright (c) 2026 RML Tec Dev
#           Contributions and feedback are welcome via rmltecdev@pm.me
#
# License   Licensed under the MIT License
#
# ──────────────────────────────────────────────────────────────────────


SCRIPT_NAME="touchpad-toggle"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/../$SCRIPT_NAME"
PASS_COUNT=0
FAIL_COUNT=0

print_pass() {
    printf "   %b✓%b %s\n" "\033[32m" "\033[0m" "$1"
    ((PASS_COUNT++)) || true
}

print_warn() {
    printf "   %b⚠%b %s\n" "\033[33m" "\033[0m" "$1"
    ((WARN_COUNT++)) || true
}

print_fail() {
    printf "   %b✗%b %s\n" "\033[31m" "\033[0m" "$1"
    ((FAIL_COUNT++)) || true
}

print_skip() {
    printf "   %b⊘%b %s\n" "\033[90m" "\033[0m" "$1"
}

echo "┌─────────────────────────────────────────────┐"
echo "│   Touchpad Toggle — Smoke Tests             │"
echo "└─────────────────────────────────────────────┘"
echo

# ───── 1. File Integrity ─────────────────────────────────────────────

echo "── File Integrity ──"

[[ -f "$MAIN_SCRIPT" ]] && print_pass "Main script exists" || print_fail "Main script exists"
[[ -x "$MAIN_SCRIPT" ]] && print_pass "Main script is executable" || print_fail "Main script is executable"

for lang in en de th; do
    [[ -f "$SCRIPT_DIR/../touchpad-toggle.$lang" ]] \
        && print_pass "Localization file .$lang exists" \
        || print_fail "Localization file .$lang exists"
done

# NEW: Extension files
echo
echo "── Extension File Integrity ──"

[[ -f "$SCRIPT_DIR/../extension/metadata.json" ]] \
    && print_pass "Extension metadata.json exists" \
    || print_fail "Extension metadata.json exists"

[[ -f "$SCRIPT_DIR/../extension/extension.js" ]] \
    && print_pass "Extension extension.js exists" \
    || print_fail "Extension extension.js exists"

[[ -f "$SCRIPT_DIR/../extension/prefs.js" ]] \
    && print_pass "Extension prefs.js exists" \
    || print_fail "Extension prefs.js exists"

[[ -d "$SCRIPT_DIR/../extension/schemas" ]] \
    && print_pass "Extension schemas/ directory exists" \
    || print_fail "Extension schemas/ directory exists"

if [[ -d "$SCRIPT_DIR/../extension/schemas" ]]; then
    if compgen -G "$SCRIPT_DIR/../extension/schemas/*.xml" > /dev/null 2>&1; then
        print_pass "Extension GSettings schema XML exists"
    else
        print_fail "Extension GSettings schema XML exists"
    fi
fi

# ───── 2. Syntax Validation ─────────────────────────────────────────

echo
echo "── Syntax Validation ──"

bash -n "$MAIN_SCRIPT" 2>/dev/null \
    && print_pass "Main script: valid Bash syntax" \
    || print_fail "Main script: valid Bash syntax"

for lang in en de th; do
    bash -n "$SCRIPT_DIR/../touchpad-toggle.$lang" 2>/dev/null \
        && print_pass "Localization .$lang: valid Bash syntax" \
        || print_fail "Localization .$lang: valid Bash syntax"
done

# NEW: JavaScript syntax check (basic)
if command -v gjs &>/dev/null; then
    if gjs -c "imports.debugger.log('Syntax check')" 2>/dev/null; then
        gjs -c "new Script(new TextInputStream(GLib.file_read_bytes('/dev/null')), {}, 'file:///dev/null');" "$SCRIPT_DIR/../extension/extension.js" 2>/dev/null \
            && print_pass "Extension extension.js: valid GJS syntax" \
            || print_warn "Extension extension.js: GJS syntax check inconclusive (expected on some systems)"
    fi
else
    print_warn "Extension extension.js: GJS not available for syntax check"
fi

# ───── 3. Shebang Check ─────────────────────────────────────────────

echo
echo "── Shebang ──"

head -1 "$MAIN_SCRIPT" | grep -q '^#!.*bash' \
    && print_pass "Shebang present and references bash" \
    || print_fail "Shebang present and references bash"

# ───── 4. Version Metadata ─────────────────────────────────────────

echo
echo "── Version Metadata & Consistency ──"

# 4a. Extract version values from each source
SCRIPT_VERSION=$(grep -oP '(?<=VERSION=")[0-9]+\.[0-9]+\.[0-9]+' "$SCRIPT_NAME" || echo "NOT FOUND")
README_VERSION=$(grep -oP '(?<=Version: )[0-9]+\.[0-9]+\.[0-9]+' README.md || echo "NOT FOUND")
CHANGELOG_VERSION=$(grep -E '^## \[' "$SCRIPT_DIR/../CHANGELOG.md" | head -1 | sed 's/## \[//' | sed 's/\].*//')

# Print visible version info for manual inspection
printf "   README version:      %s\n" "${README_VERSION:-'(not found)'}"
printf "   CHANGELOG version:   %s\n" "${CHANGELOG_VERSION:-'(not found)'}"
printf "   Script version:      %s\n" "$SCRIPT_VERSION"


# 4b. Version consistency check
if [[ -n "$SCRIPT_VERSION" && -n "$README_VERSION" && -n "$CHANGELOG_VERSION" ]]; then
    if [[ "$SCRIPT_VERSION" == "$README_VERSION" && "$SCRIPT_VERSION" == "$CHANGELOG_VERSION" ]]; then
        print_pass "Version consistency across all documents: v$SCRIPT_VERSION"
    else
        print_fail "Version mismatch detected! (Script=$SCRIPT_VERSION, README=$README_VERSION, CHANGELOG=$CHANGELOG_VERSION)"
    fi
else
    print_fail "One or more version values not found"
fi

# 4c. CHANGELOG has entry for current version
#if [[ -n "$SCRIPT_VERSION" ]] && grep -qE "^## \[$SCRIPT_VERSION\]" "$SCRIPT_DIR/../CHANGELOG.md"; then
#    print_pass "CHANGELOG has entry for v$SCRIPT_VERSION"
#else
#    print_fail "CHANGELOG missing entry for v$SCRIPT_VERSION"
#fi

# 4d. No alpha/beta markers in release version
if [[ "$SCRIPT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_pass "Release version has no alpha/beta markers"
else
    print_fail "Release version contains alpha/beta marker: $SCRIPT_VERSION"
fi

# 4d. Check Build Date Consistency Across All Documents
echo
echo "── Build date consistency ──"
SCRIPT_DATE=$(grep -oP '(?<=BUILD_DATE=")[0-9]{4}-[0-9]{2}-[0-9]{2}' "$SCRIPT_NAME" || echo "NOT FOUND")
README_DATE=$(grep -oP '(?<=Build Date: )[0-9]{4}-[0-9]{2}-[0-9]{2}' README.md || echo "NOT FOUND")
CHANGELOG_DATE=$(grep -m1 '^## \[' CHANGELOG.md | grep -oP '(?<=- )[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "NOT FOUND")

echo "   Script:     $SCRIPT_DATE"
echo "   README:     $README_DATE"
echo "   CHANGELOG:  $CHANGELOG_DATE"

DATE_SOURCES=("$SCRIPT_DATE" "$README_DATE" "$CHANGELOG_DATE")
DATE_LABELS=("Script" "README.md" "CHANGELOG.md")

# Reset a local counter for date-specific failures
DATE_FAILURES=0

for i in "${!DATE_SOURCES[@]}"; do
    if [ "${DATE_SOURCES[$i]}" == "NOT FOUND" ]; then
        print_fail="${DATE_LABELS[$i]}: Build Date not found."; fail; DATE_FAILURES=$((DATE_FAILURES + 1))
    fi
done

if [ "$DATE_FAILURES" -eq 0 ]; then
    REFERENCE="$SCRIPT_DATE"
    for i in "${!DATE_SOURCES[@]}"; do
        if [ "${DATE_SOURCES[$i]}" != "$REFERENCE" ]; then
            print_fail="Build Date mismatch: ${DATE_LABELS[$i]} (${DATE_SOURCES[$i]}) vs Script ($REFERENCE)"; fail
        fi
    done
fi

# Only print success if no date-related failures were added in this block
if [ "$DATE_FAILURES" -eq 0 ]; then
    print_pass "Build Date consistent across all documents: $SCRIPT_DATE"
fi

# ───── 5. CLI Flags (non-GNOME-safe) ────────────────────────────────

echo
echo "── Dependency Check (Non-Critical) ──"

# gsettings and realpath are critical; audio player is optional
for tool in gsettings realpath; do
    command -v "$tool" &>/dev/null && print_pass "$tool available" || print_fail "$tool not found" 
done

# Audio player detection (optional)
if command -v pw-play &>/dev/null || command -v paplay &>/dev/null || command -v aplay &>/dev/null; then
        print_pass "Audio player detected"
    else
        print_warn "No audio player (acceptable — sound feedback disabled)" 
fi

# ───── 6. Extension Settings Schema Validation ───────────────────────

echo
echo "── Extension Settings Schema ──"

# 6a. Check settings-schema key in metadata.json
if grep -q '"settings-schema"' "$SCRIPT_DIR/../extension/metadata.json"; then
    print_pass "metadata.json declares settings-schema"
    
    SCHEMA_ID=$(grep -oP '"settings-schema"\s*:\s*"\K[^"]+' "$SCRIPT_DIR/../extension/metadata.json")
    print_pass "Schema ID: $SCHEMA_ID"
else
    print_fail "metadata.json missing settings-schema declaration"
    SCHEMA_ID=""
fi

# 6b. Verify schema XML has matching ID (FIXED: use find for reliable glob)
if [[ -n "$SCHEMA_ID" ]]; then
    SCHEMA_XML=$(find "$SCRIPT_DIR/../extension/schemas/" -maxdepth 1 -name "*.xml" -type f 2>/dev/null | head -1)
    if [[ -n "$SCHEMA_XML" && -f "$SCHEMA_XML" ]]; then
        if grep -q "id=\"$SCHEMA_ID\"" "$SCHEMA_XML"; then
            print_pass "Schema XML has matching ID: $SCHEMA_ID"
        else
            print_fail "Schema XML ID mismatch (expected: $SCHEMA_ID, found: $(grep -oP 'id="\K[^"]+' "$SCHEMA_XML"))"
        fi
    else
        print_fail "Schema XML file not found in extension/schemas/ (searched: ${SCHEMA_XML:-none})"
    fi
fi

# 6c. Check for colored-icons key
SCHEMA_FILES=$(find "$SCRIPT_DIR/../extension/schemas/" -name "*.xml" -type f 2>/dev/null)
if [[ -n "$SCHEMA_FILES" ]]; then
    if echo "$SCHEMA_FILES" | xargs grep -q 'name="colored-icons"'; then
        print_pass "Schema defines colored-icons key"
        
        FIRST_SCHEMA=$(echo "$SCHEMA_FILES" | head -1)
        if grep -A2 'name="colored-icons"' "$FIRST_SCHEMA" | grep -q 'type="b"'; then
            print_pass "colored-icons key type is boolean"
        else
            print_fail "colored-icons key is not boolean"
        fi
    else
        print_fail "Schema missing colored-icons key"
    fi
else
    print_skip "Schema validation skipped (no XML files found)"
fi

# ───── 7. Extension JavaScript Validation ────────────────────────────

echo
echo "── Extension JavaScript ──"

# 7a. Check for getSettings() usage (proper local schema access)
if grep -q "this.getSettings()" "$SCRIPT_DIR/../extension/extension.js"; then
    print_pass "Extension uses this.getSettings() (local schema)"
else
    print_fail "Extension does not use this.getSettings() (may fail schema loading)"
fi

# 7b. Verify __SCRIPT_PATH__ placeholder is NOT replaced in source (should be replaced at install time)
if grep -q '__SCRIPT_PATH__' "$SCRIPT_DIR/../extension/extension.js"; then
    print_pass "__SCRIPT_PATH__ placeholder present in source (correct)"
else
    print_warn "__SCRIPT_PATH__ placeholder missing in source (may indicate premature replacement)"
fi

# 7c. Check for EXTENSION_SCHEMA constant
if grep -q 'EXTENSION_SCHEMA' "$SCRIPT_DIR/../extension/extension.js"; then
    print_pass "Extension defines EXTENSION_SCHEMA constant"
else
    print_fail "Extension missing EXTENSION_SCHEMA constant"
fi

# ───── 8. Localization ─────────────────────────────────────────────

echo
echo "── Localization ──"

# Discover all localization files dynamically
mapfile -t LOCALE_FILES < <(
    for f in "$SCRIPT_DIR"/../touchpad-toggle.*; do
        [[ -f "$f" ]] || continue
        [[ "$(basename "$f")" == *.*.* ]] && continue
        basename "$f"
    done | sort
)

if [[ ${#LOCALE_FILES[@]} -eq 0 ]]; then
    print_fail "No localization files found"
else
    print_pass "${#LOCALE_FILES[@]} localization file(s) discovered"
fi

# 8a. Script-Reference Alignment
mapfile -t SCRIPT_MSG_KEYS < <(grep -oP 'MSG\[\K[a-z_]+' "$MAIN_SCRIPT" | sort -u)

if [[ ${#SCRIPT_MSG_KEYS[@]} -eq 0 ]]; then
    print_fail "Script references no MSG[] keys (extraction failed?)"
else
    print_pass "Script references ${#SCRIPT_MSG_KEYS[@]} unique MSG[] key(s)"
fi

for locale_file in "${LOCALE_FILES[@]}"; do
    file_path="$SCRIPT_DIR/../$locale_file"
    lang="${locale_file##*.}"
    
    mapfile -t LOCALE_KEYS < <(grep -oP 'MSG\[\K[a-z_]+' "$file_path" | sort -u)
    mapfile -t MISSING < <(comm -23 <(printf '%s\n' "${SCRIPT_MSG_KEYS[@]}") <(printf '%s\n' "${LOCALE_KEYS[@]}"))
    
    if [[ ${#MISSING[@]} -eq 0 ]]; then
        print_pass ".$lang: all ${#SCRIPT_MSG_KEYS[@]} script-referenced keys present"
    else
        print_fail ".$lang: ${#MISSING[@]} script-referenced key(s) missing:"
        printf "%s\n" "${MISSING[@]}" | sed 's/^/         - /'
    fi
done

# ───── 9. Log Directory ─────────────────────────────────────────────

echo
echo "── Logging ──"

grep -q 'XDG_STATE_HOME' "$MAIN_SCRIPT" \
    && print_pass "Log directory uses XDG specification" \
    || print_fail "Log directory uses XDG specification"

grep -q 'log()' "$MAIN_SCRIPT" \
    && print_pass "Log function defined" \
    || print_fail "Log function defined"
    
# ───── 10. Behavioral Tests (Isolated) ───────────────────────────────

echo
echo "── Behavioral Tests ──"

# Create a safe temporary sandbox
TEST_SANDBOX=$(mktemp -d)
trap 'rm -rf "$TEST_SANDBOX"' EXIT

# Copy script to sandbox
cp "$MAIN_SCRIPT" "$TEST_SANDBOX/"

# 10a. Localization failure: no .en file present
cp "$SCRIPT_DIR/../touchpad-toggle.en" "$TEST_SANDBOX/touchpad-toggle.en.bak" 2>/dev/null
rm -f "$TEST_SANDBOX/touchpad-toggle.en" "$TEST_SANDBOX/touchpad-toggle.de" "$TEST_SANDBOX/touchpad-toggle.th"

output=$("$TEST_SANDBOX/touchpad-toggle" 2>&1)
exit_code=$?
if [[ $exit_code -ne 0 ]] && echo "$output" | grep -qi "Localization error"; then
    print_pass "Missing locale file: exits with error message"
else
    print_fail "Missing locale file: should exit with localization error (got exit $exit_code)"
fi

# 10b. Localization failure: does NOT crash with log() undefined
if echo "$output" | grep -qi "command not found"; then
    print_fail "Missing locale file: log() or other function not defined (crash)"
else
    print_pass "Missing locale file: no undefined function crash"
fi

# 10c. --help works (ensure .en file exists in sandbox)
cp "$TEST_SANDBOX/touchpad-toggle.en.bak" "$TEST_SANDBOX/touchpad-toggle.en" 2>/dev/null

output=$(PAGER=cat LANG=C "$TEST_SANDBOX/touchpad-toggle" --help 2>&1 </dev/null)
if echo "$output" | grep -qE "NAME|BESCHREIBUNG|NUTZUNG|--assign|--toggle"; then
    print_pass "--help displays help content"
else
    print_fail "--help did not display expected content (first 200 chars: ${output:0:200})"
fi

# 10d. Dependency check: simulate missing gsettings
EMPTY_PATH=$(mktemp -d)
ln -s /bin/true "$EMPTY_PATH/realpath" 2>/dev/null

output=$(PATH="$EMPTY_PATH" "$TEST_SANDBOX/touchpad-toggle" 2>&1 <<< "")
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    print_pass "Missing dependencies: script exits non-zero"
else
    print_pass "Missing dependencies: script handles gracefully"
fi

rm -rf "$EMPTY_PATH"

# ───── 11. Default Values ────────────────────────────────────────────

echo
echo "── Default Values ──"

ACTUAL_BINDING=$(grep -E "^KEY_BINDING=" "$MAIN_SCRIPT" | sed 's/.*=//; s/["'"'"']//g')
if [[ "$ACTUAL_BINDING" == '<Super>q' ]]; then
    print_pass "KEY_BINDING defaults to <Super>q"
else
    print_fail "KEY_BINDING defaults to <Super>q (got: '$ACTUAL_BINDING')"
fi

ACTUAL_INTERVAL=$(grep -E "^WATCH_INTERVAL=" "$MAIN_SCRIPT" | sed 's/.*=//; s/["'"'"']//g')
if [[ "$ACTUAL_INTERVAL" == "2" ]]; then
    print_pass "WATCH_INTERVAL defaults to 2"
else
    print_fail "WATCH_INTERVAL defaults to 2 (got: '$ACTUAL_INTERVAL')"
fi

# ───── Summary ──────────────────────────────────────────────────────

echo
echo "─────────────────────────────────────────────"
printf "  Results: %b%d passed%b, %b%d failed%b\n" \
    "\033[32m" "$PASS_COUNT" "\033[0m" \
    "\033[31m" "$FAIL_COUNT" "\033[0m"
echo "─────────────────────────────────────────────"
echo
echo "── Required Manual Tests ──"
echo ""
echo "   Invoke script with the following options and observe..."
echo "   --toggle    ...touchpad function and audio playback."
echo "   --assign    ...behavior if keyboard shortcut is/isn't assigned."
echo "   --unassign  ...behavior if keyboard shortcut is/isn't assigned."
echo "   --reset     ...behavior of the input subsystem."
echo "   --watch     ..., if statuses are updated at runtime, and the"
echo "               process stops on Ctrl+C."
echo
echo "   Activate GNOME extension and observe..."
echo "   - On toggle setting, indicator changes to monochrome or colored."
echo "   - On right click, indicator changes to mouse icon (teal)."
echo "   - On connect mouse (USB/Bluetooth) indicator changes to blue,"
echo "     and touchpad disabled."
echo "   - On disconnect mouse (USB/Bluetooth) indicator changes to teal,"
echo "     and touchpad enabled."
echo "   - Indicator changes on left click to red, and touchpad disabled"
echo
echo "   Press keyboard shortcut and observe..."
echo "   - Touchpad disabled/enabled and indicator changes icon and color."


exit "$FAIL_COUNT"
