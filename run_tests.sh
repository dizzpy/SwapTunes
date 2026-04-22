#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

BACKEND_LOG=$(mktemp)
FRONTEND_LOG=$(mktemp)
BACKEND_EXIT_FILE=$(mktemp)
FRONTEND_EXIT_FILE=$(mktemp)

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}SwapTunes — Test Suite${RESET}\n"
echo "════════════════════════════════════════"

# ── Backend (Jest) ────────────────────────────────────────────────────────────
# A custom Jest reporter streams per-test ✓/✗ lines to stdout in real-time.
# tee captures the full merged output in BACKEND_LOG for summary parsing.
echo ""
printf "${CYAN}${BOLD}▸ Backend  (Jest)${RESET}\n"
echo "────────────────────────────────────────"

BACKEND_START=$SECONDS
(
  cd "$ROOT_DIR/backend"
  npm test -- --runInBand 2>&1
  echo $? > "$BACKEND_EXIT_FILE"
) | tee "$BACKEND_LOG" \
  | grep -E "^  [✓✗] "

BACKEND_TIME="$((SECONDS - BACKEND_START))s"
BACKEND_EXIT=$(cat "$BACKEND_EXIT_FILE" 2>/dev/null || echo 1)
[[ "$BACKEND_EXIT" == "0" ]] && BACKEND_STATUS="PASSED" || BACKEND_STATUS="FAILED"

# ── Frontend (Flutter) ────────────────────────────────────────────────────────
# Stream test results in real-time.
# Flutter prints each test twice (once on start, once on completion); the awk
# deduplicate step only outputs a line when the pass-count increments (+N
# increases), so each test appears exactly once. Failure lines (+N -M:) are
# always passed through immediately.
echo ""
printf "${CYAN}${BOLD}▸ Frontend  (Flutter)${RESET}\n"
echo "────────────────────────────────────────"

FRONTEND_START=$SECONDS
(
  cd "$ROOT_DIR/frontend"
  flutter test 2>&1
  echo $? > "$FRONTEND_EXIT_FILE"
) | tee "$FRONTEND_LOG" \
  | grep -E "^\s*[0-9]+:[0-9]+ \+[0-9]+" \
  | grep -v " loading " \
  | awk '
      /[+][0-9]+ -[0-9]+:/ { print; next }
      /[+][0-9]+/ {
        match($0, /[+][0-9]+/)
        n = substr($0, RSTART+1, RLENGTH-1) + 0
        if (n > prev) { print; prev = n }
      }
    ' \
  | grep -Ev "All tests passed|Some tests failed" \
  | sed -E 's/^[[:space:]]*[0-9]+:[0-9]+ \+[0-9]+ -[0-9]+: (.*) \[E\]$/  ✗ \1/' \
  | sed -E 's/^[[:space:]]*[0-9]+:[0-9]+ \+[0-9]+: /  ✓ /' \
  | sed 's|.*/test/||'

FRONTEND_TIME="$((SECONDS - FRONTEND_START))s"
FRONTEND_EXIT=$(cat "$FRONTEND_EXIT_FILE" 2>/dev/null || echo 1)
[[ "$FRONTEND_EXIT" == "0" ]] && FRONTEND_STATUS="PASSED" || FRONTEND_STATUS="FAILED"

# ── Parse counts ──────────────────────────────────────────────────────────────
# Backend: "Tests:       39 passed, 0 failed, 39 total"
BACKEND_PASSED=$(grep "^Tests:" "$BACKEND_LOG" | grep -oE "[0-9]+ passed" | grep -oE "[0-9]+" | head -1)
BACKEND_FAILED=$(grep "^Tests:" "$BACKEND_LOG" | grep -oE "[0-9]+ failed" | grep -oE "[0-9]+" | head -1)
BACKEND_SUITES=$(grep "^Test Suites:" "$BACKEND_LOG" | grep -oE "[0-9]+ passed" | grep -oE "[0-9]+" | head -1)
[[ -z "$BACKEND_PASSED" ]] && BACKEND_PASSED=0
[[ -z "$BACKEND_FAILED" ]] && BACKEND_FAILED=0
[[ -z "$BACKEND_SUITES" ]] && BACKEND_SUITES=0
BACKEND_TOTAL=$((BACKEND_PASSED + BACKEND_FAILED))

# Frontend: passing run ends with "+153: All tests passed!"
#           failing run ends with "+153 -11: Some tests failed."
FLUTTER_TOKEN=$(grep -oE "\+[0-9]+( -[0-9]+)?:" "$FRONTEND_LOG" | tail -1)
FRONTEND_PASSED=$(echo "$FLUTTER_TOKEN" | grep -oE "\+[0-9]+" | tr -d '+')
FRONTEND_FAILED=$(echo "$FLUTTER_TOKEN" | grep -oE "\-[0-9]+" | tr -d '-')
[[ -z "$FRONTEND_PASSED" ]] && FRONTEND_PASSED=0
[[ -z "$FRONTEND_FAILED" ]] && FRONTEND_FAILED=0
FRONTEND_TOTAL=$((FRONTEND_PASSED + FRONTEND_FAILED))

ALL_TOTAL=$((BACKEND_TOTAL + FRONTEND_TOTAL))
ALL_FAILED=$((BACKEND_FAILED + FRONTEND_FAILED))

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
printf "${BOLD}Results${RESET}\n"
echo "════════════════════════════════════════"
echo ""

if [[ "$BACKEND_STATUS" == "PASSED" ]]; then
  printf "  Backend   ${GREEN}${BOLD}PASSED${RESET}\n"
else
  printf "  Backend   ${RED}${BOLD}FAILED${RESET}\n"
fi
printf "  ${DIM}$BACKEND_TOTAL tests — $BACKEND_PASSED passed, $BACKEND_FAILED failed ($BACKEND_SUITES suites, ${BACKEND_TIME})${RESET}\n"

if [[ "$BACKEND_STATUS" == "FAILED" ]]; then
  echo "  Issues:"
  grep "● " "$BACKEND_LOG" 2>/dev/null \
    | sed 's/.*● //' \
    | sed 's/^/    - /' \
    | cut -c1-72 \
    | head -10
fi

echo ""

if [[ "$FRONTEND_STATUS" == "PASSED" ]]; then
  printf "  Frontend  ${GREEN}${BOLD}PASSED${RESET}\n"
else
  printf "  Frontend  ${RED}${BOLD}FAILED${RESET}\n"
fi
printf "  ${DIM}$FRONTEND_TOTAL tests — $FRONTEND_PASSED passed, $FRONTEND_FAILED failed (${FRONTEND_TIME})${RESET}\n"

if [[ "$FRONTEND_STATUS" == "FAILED" ]]; then
  echo "  Issues:"
  grep "\[E\]" "$FRONTEND_LOG" 2>/dev/null \
    | sed 's/.*+[0-9]* -[0-9]*: //' \
    | sed 's/ \[E\]//' \
    | sed 's|.*/test/||' \
    | sed 's/^/    - /' \
    | cut -c1-72 \
    | head -15
fi

echo ""
echo "════════════════════════════════════════"
if [[ "$BACKEND_STATUS" == "PASSED" && "$FRONTEND_STATUS" == "PASSED" ]]; then
  printf "  ${GREEN}${BOLD}$ALL_TOTAL tests — all passed${RESET}\n"
else
  printf "  ${RED}${BOLD}$ALL_TOTAL tests — $ALL_FAILED issues need to fix${RESET}\n"
fi
echo "════════════════════════════════════════"
echo ""

rm -f "$BACKEND_LOG" "$FRONTEND_LOG" "$BACKEND_EXIT_FILE" "$FRONTEND_EXIT_FILE"

[[ "$BACKEND_STATUS" == "PASSED" && "$FRONTEND_STATUS" == "PASSED" ]] && exit 0
exit 1
