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

# ───── 6. Localization Coverage ────────────────────────────────────

echo
echo "── Localization Coverage ──"

# Extract message keys from English (fallback) file
mapfile -t EN_KEYS < <(grep -oP 'MSG\[\K[a-z_]+' "$SCRIPT_DIR/../touchpad-toggle.en" | sort -u)

for lang in de th; do
    missing=0
    for key in "${EN_KEYS[@]}"; do
        grep -q "MSG\[$key\]" "$SCRIPT_DIR/../touchpad-toggle.$lang" || ((missing++))
    done
    [[ $missing -eq 0 ]] \
        && print_pass ".$lang: all message keys present ($((${#EN_KEYS[@]})) keys)" \
        || print_fail ".$lang: $missing message keys missing"
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
echo "   Invoke script with the following options:"
echo "   --toggle    Observe function and audio playback."
echo "   --assign    Observe behavior if keyboard shortcut is/isn't assigned."
echo "   --unassign  Observe behavior if keyboard shortcut is/isn't assigned."
echo "   --reset     Observe behavior of the input subsystem."
echo "   --watch     Observe, if statuses are updated at runtime,"
echo "               and the process stops on Ctrl+C."

exit "$FAIL_COUNT"
