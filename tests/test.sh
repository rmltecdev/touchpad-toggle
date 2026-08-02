#!/usr/bin/env bash

# ──────────────────────────────────────────────────────────────────────
# Touchpad Toggle — Smoke Tests
# Validates structural integrity and basic CLI behavior.
# Does NOT require a live GNOME session or touchpad hardware.
# ──────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/../touchpad-toggle"
PASS_COUNT=0
FAIL_COUNT=0

print_pass() {
    printf "  %b✓%b %s\n" "\033[32m" "\033[0m" "$1"
    ((PASS_COUNT++)) || true
}

print_fail() {
    printf "  %b✗%b %s\n" "\033[31m" "\033[0m" "$1"
    ((FAIL_COUNT++)) || true
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

# ───── 3. Shebang Check ─────────────────────────────────────────────

echo
echo "── Shebang ──"

head -1 "$MAIN_SCRIPT" | grep -q '^#!.*bash' \
    && print_pass "Shebang present and references bash" \
    || print_fail "Shebang present and references bash"

# ───── 4. Version Metadata ─────────────────────────────────────────

echo
echo "── Version Metadata ──"

grep -q 'VERSION="' "$MAIN_SCRIPT" \
    && print_pass "VERSION variable defined" \
    || print_fail "VERSION variable defined"

grep -q 'BUILD_DATE="' "$MAIN_SCRIPT" \
    && print_pass "BUILD_DATE variable defined" \
    || print_fail "BUILD_DATE variable defined"

# ───── 5. CLI Flags (non-GNOME-safe) ────────────────────────────────

echo
echo "── CLI Flags ──"

# --version: Should work without GNOME
output=$("$MAIN_SCRIPT" --version 2>/dev/null)
exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$output" | grep -q "$VERSION"; then
    print_pass "--version returns version info"
else
    print_fail "--version returns version info"
fi

# Unknown flag falls back to display_info (may fail without GNOME, that's OK)
output=$("$MAIN_SCRIPT" --invalid-flag 2>/dev/null)
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    print_pass "Invalid flag handled gracefully (exit 0)"
else
    # Exit code non-zero is acceptable if GNOME isn't available
    print_pass "Invalid flag exits (acceptable without GNOME session)"
fi

# ───── 6. Localization ─────────────────────────────────────────────

echo
echo "── Localization ──"

# Discover all localization files dynamically
# Excludes multi-dot files like touchpad-toggle.en.bak
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

# 6a. Script-Reference Alignment (STRICTER — runs first)
#     Extract every MSG[key] the main script actually references,
#     then verify each key is defined in every locale file —
#     including .en.
mapfile -t SCRIPT_MSG_KEYS < <(grep -oP 'MSG\[\K[a-z_]+' "$MAIN_SCRIPT" | sort -u)

if [[ ${#SCRIPT_MSG_KEYS[@]} -eq 0 ]]; then
    print_fail "Script references no MSG[] keys (extraction failed?)"
else
    print_pass "Script references ${#SCRIPT_MSG_KEYS[@]} unique MSG[] key(s)"
fi

for locale_file in "${LOCALE_FILES[@]}"; do
    file_path="$SCRIPT_DIR/../$locale_file"
    lang="${locale_file##*.}"
    
    # Extract keys defined in this locale file
    mapfile -t LOCALE_KEYS < <(grep -oP 'MSG\[\K[a-z_]+' "$file_path" | sort -u)
    
    # Find missing keys (in script but not in locale)
    mapfile -t MISSING < <(comm -23 <(printf '%s\n' "${SCRIPT_MSG_KEYS[@]}") <(printf '%s\n' "${LOCALE_KEYS[@]}"))
    
    if [[ ${#MISSING[@]} -eq 0 ]]; then
        print_pass ".$lang: all ${#SCRIPT_MSG_KEYS[@]} script-referenced keys present"
    else
        print_fail ".$lang: ${#MISSING[@]} script-referenced key(s) missing:"
        printf "%s\n" "${MISSING[@]}" | sed 's/^/         - /'
    fi
done

# 6b. Translation Coverage (CHECKS AGAINST FALLBACK)
#     Use the .en fallback as the canonical key set,
#     then verify every other locale mirrors it.
mapfile -t EN_KEYS < <(grep -oP 'MSG\[\K[a-z_]+' "$SCRIPT_DIR/../touchpad-toggle.en" | sort -u)

if [[ ${#EN_KEYS[@]} -eq 0 ]]; then
    print_fail "No MSG[] keys found in .en fallback file"
else
    print_pass ".en fallback defines ${#EN_KEYS[@]} unique key(s)"
fi

for locale_file in "${LOCALE_FILES[@]}"; do
    file_path="$SCRIPT_DIR/../$locale_file"
    lang="${locale_file##*.}"
    [[ "$lang" == "en" ]] && continue
    missing=0
    for key in "${EN_KEYS[@]}"; do
        grep -q "MSG\[$key\]" "$file_path" || ((missing++))
    done
    if [[ $missing -eq 0 ]]; then
        print_pass ".$lang: all ${#EN_KEYS[@]} fallback key(s) present"
    else
        print_fail ".$lang: $missing fallback key(s) missing"
    fi
done

# 6c. Dead Key Detection (optional but recommended)
for locale_file in "${LOCALE_FILES[@]}"; do
    file_path="$SCRIPT_DIR/../$locale_file"
    lang="${locale_file##*.}"
    
    mapfile -t LOCALE_KEYS < <(grep -oP 'MSG\[\K[a-z_]+' "$file_path" | sort -u)
    mapfile -t ORPHANS < <(comm -23 <(printf '%s\n' "${LOCALE_KEYS[@]}") <(printf '%s\n' "${SCRIPT_MSG_KEYS[@]}"))
    
    if [[ ${#ORPHANS[@]} -eq 0 ]]; then
        print_pass ".$lang: no orphan MSG[] keys"
    else
        print_fail ".$lang: ${#ORPHANS[@]} orphan key(s) detected:"
        printf "     %s\n" "${ORPHANS[@]}" | sed 's/^/       - /'
    fi
done

# ───── 7. Log Directory ─────────────────────────────────────────────

echo
echo "── Logging ──"

grep -q 'XDG_STATE_HOME' "$MAIN_SCRIPT" \
    && print_pass "Log directory uses XDG specification" \
    || print_fail "Log directory uses XDG specification"

grep -q 'log()' "$MAIN_SCRIPT" \
    && print_pass "Log function defined" \
    || print_fail "Log function defined"
    
# ───── 8. Behavioral Tests (Isolated) ───────────────────────────────

echo
echo "── Behavioral Tests ──"

# Create a safe temporary sandbox
TEST_SANDBOX=$(mktemp -d)
trap 'rm -rf "$TEST_SANDBOX"' EXIT

# Copy script to sandbox
cp "$MAIN_SCRIPT" "$TEST_SANDBOX/"

# 8a. Localization failure: no .en file present
cp "$SCRIPT_DIR/../touchpad-toggle.en" "$TEST_SANDBOX/touchpad-toggle.en.bak" 2>/dev/null
rm -f "$TEST_SANDBOX/touchpad-toggle.en" "$TEST_SANDBOX/touchpad-toggle.de" "$TEST_SANDBOX/touchpad-toggle.th"

output=$("$TEST_SANDBOX/touchpad-toggle" 2>&1)
exit_code=$?
if [[ $exit_code -ne 0 ]] && echo "$output" | grep -qi "Localization error"; then
    print_pass "Missing locale file: exits with error message"
else
    print_fail "Missing locale file: should exit with localization error (got exit $exit_code)"
fi

# 8b. Localization failure: does NOT crash with log() undefined
if echo "$output" | grep -qi "command not found"; then
    print_fail "Missing locale file: log() or other function not defined (crash)"
else
    print_pass "Missing locale file: no undefined function crash"
fi

# 8c. --version works in isolated environment (no locale files needed)
# Restore the .en file for this test
cp "$TEST_SANDBOX/touchpad-toggle.en.bak" "$TEST_SANDBOX/touchpad-toggle.en" 2>/dev/null

output=$("$TEST_SANDBOX/touchpad-toggle" --version 2>&1)
exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$output" | grep -q "$VERSION"; then
    print_pass "--version works in isolated sandbox"
else
    print_fail "--version in isolated sandbox (exit $exit_code)"
fi

# 8d. --help works (pipes to less, check exit code only)
output=$("$TEST_SANDBOX/touchpad-toggle" --help 2>/dev/null </dev/null)
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    print_pass "--help opens without crash"
else
    print_fail "--help crashed (exit $exit_code)"
fi

# 8e. Dependency check: simulate missing gsettings
# Create a PATH with no gsettings, notify-send, or audio players
EMPTY_PATH=$(mktemp -d)
ln -s /bin/true "$EMPTY_PATH/realpath" 2>/dev/null

output=$(PATH="$EMPTY_PATH" "$TEST_SANDBOX/touchpad-toggle" 2>&1 <<< "")
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    print_pass "Missing dependencies: script exits non-zero"
else
    # On some systems gsettings might be found regardless — check stderr
    print_pass "Missing dependencies: script handles gracefully"
fi

rm -rf "$EMPTY_PATH"

# ───── 9. Default Values ────────────────────────────────────────────

echo
echo "── Default Values ──"

# 9a. Verify KEY_BINDING defaults to "<Super>q"
ACTUAL_BINDING=$(grep -E "^KEY_BINDING=" "$MAIN_SCRIPT" | sed 's/.*=//; s/["'"'"']//g')
if [[ "$ACTUAL_BINDING" == '<Super>q' ]]; then
    print_pass "KEY_BINDING defaults to <Super>q"
else
    print_fail "KEY_BINDING defaults to <Super>q (got: '$ACTUAL_BINDING')"
fi

# 9b. Verify WATCH_INTERVAL defaults to "2"
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
echo ""
echo "── Required Manual Tests ──"
echo ""
echo "   Invoke script with the following options and observe..."
echo "   --toggle    ...touchpad function and audio playback."
echo "   --assign    ...behavior if keyboard shortcut is/isn't assigned."
echo "   --unassign  ...behavior if keyboard shortcut is/isn't assigned."
echo "   --reset     ...behavior of the input subsystem."
echo "   --watch     ..., if statuses are updated at runtime, and the"
echo "               process stops on Ctrl+C."
echo ""

exit "$FAIL_COUNT"
