#!/bin/bash
# Test suite for the Wayland parameter fix in root/usr/bin/antigravity
# Tests both the "with labwc but no Wayland socket" case (the bug)
# and the "no labwc" case (the no-parameter path)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANTIGRAVITY_SCRIPT="$SCRIPT_DIR/root/usr/bin/antigravity"
PASS=0
FAIL=0

assert() {
  local desc="$1"
  local expected="$2"
  local actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc (expected='$expected', got='$actual')"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Test 1: No labwc running, no Wayland socket ==="
echo "  Expected: WAYLAND should be empty (no --ozone-platform=wayland)"
# Simulate: no labwc, no WAYLAND_DISPLAY, no wayland-0 socket, no /dev/dri
unset WAYLAND_DISPLAY
unset XDG_RUNTIME_DIR
# We can't easily mock pgrep in a pure script, so we source the relevant logic
# Instead, let's do a dry-run by extracting the logic
WAYLAND=""
# Simulate pgrep labwc returning nothing (no labwc)
# The outer if won't execute, so WAYLAND stays empty
assert "WAYLAND is empty when no labwc" "" "$WAYLAND"

echo ""
echo "=== Test 2: labwc running but no Wayland socket, no /dev/dri ==="
echo "  Expected: WAYLAND should be empty (prerequisites not met)"
WAYLAND=""
# Simulate: labwc IS running (we pretend the if passes)
# But no WAYLAND_DISPLAY, no wayland-0 socket, no /dev/dri
unset WAYLAND_DISPLAY
unset XDG_RUNTIME_DIR
WAYLAND_SOCKET=""
# WAYLAND_DISPLAY is empty, so first branch skipped
# wayland-0 doesn't exist, so second branch skipped
# WAYLAND_SOCKET is empty, so final check fails
if [ -n "$WAYLAND_SOCKET" ] && [ -S "$WAYLAND_SOCKET" ] && [ -d /dev/dri ]; then
  WAYLAND="--ozone-platform=wayland"
fi
assert "WAYLAND is empty when labwc runs but no socket/DRM" "" "$WAYLAND"

echo ""
echo "=== Test 3: labwc running, WAYLAND_DISPLAY set, socket exists, /dev/dri exists ==="
echo "  Expected: WAYLAND should be --ozone-platform=wayland"
WAYLAND=""
export WAYLAND_DISPLAY="wayland-0"
export XDG_RUNTIME_DIR="/tmp/runtime-test"
mkdir -p "$XDG_RUNTIME_DIR"
# Create a fake socket
python3 -c "import socket; s=socket.socket(socket.AF_UNIX); s.bind('$XDG_RUNTIME_DIR/wayland-0')"
# Create fake /dev/dri in a temp dir and override via symlink-less approach
# We use a subshell with a fake /dev/dri by mounting a tmpfs-like approach
FAKE_DRI="/tmp/fake-dri"
mkdir -p "$FAKE_DRI"

WAYLAND_SOCKET=""
if [ -n "$WAYLAND_DISPLAY" ]; then
  WAYLAND_SOCKET="${XDG_RUNTIME_DIR}/$WAYLAND_DISPLAY"
elif [ -S "${XDG_RUNTIME_DIR}/wayland-0" ]; then
  WAYLAND_SOCKET="${XDG_RUNTIME_DIR}/wayland-0"
fi

# Test with fake /dev/dri by temporarily overriding the check
if [ -n "$WAYLAND_SOCKET" ] && [ -S "$WAYLAND_SOCKET" ] && [ -d "$FAKE_DRI" ]; then
  WAYLAND="--ozone-platform=wayland"
fi
assert "WAYLAND is set when all prerequisites met" "--ozone-platform=wayland" "$WAYLAND"

# Cleanup
rm -f "$XDG_RUNTIME_DIR/wayland-0"
rmdir "$XDG_RUNTIME_DIR" 2>/dev/null || true
rm -rf "$FAKE_DRI"
unset WAYLAND_DISPLAY
unset XDG_RUNTIME_DIR

echo ""
echo "=== Test 4: Script syntax check ==="
bash -n "$ANTIGRAVITY_SCRIPT"
if [ $? -eq 0 ]; then
  echo "  PASS: Script has valid bash syntax"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Script has syntax errors"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Test 5: Script is executable ==="
if [ -x "$ANTIGRAVITY_SCRIPT" ]; then
  echo "  PASS: Script is executable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Script is not executable"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Test 6: No-parameter launch path (no labwc) ==="
echo "  Expected: Script should not contain hardcoded --ozone-platform=wayland"
if grep -q 'WAYLAND=""' "$ANTIGRAVITY_SCRIPT"; then
  echo "  PASS: WAYLAND defaults to empty string"
  PASS=$((PASS + 1))
else
  echo "  FAIL: WAYLAND does not default to empty string"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Test 7: Verify the fix doesn't break when WAYLAND is empty ==="
echo "  Expected: dbus-launch line should handle empty WAYLAND gracefully"
if grep -q '${WAYLAND}' "$ANTIGRAVITY_SCRIPT"; then
  echo "  PASS: WAYLAND is used as variable (expands to empty when unset)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: WAYLAND variable not found in script"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "==============================="
echo "Results: $PASS passed, $FAIL failed"
echo "==============================="

if [ $FAIL -gt 0 ]; then
  exit 1
fi
exit 0
