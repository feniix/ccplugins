#!/bin/bash
# Test runner for safety-hooks plugin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
export PYTHONPATH="$PLUGIN_ROOT/hooks:$PYTHONPATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Overall stats
TOTAL_RUN=0
TOTAL_PASSED=0
TOTAL_FAILED=0

echo -e "${BLUE}========================================"
echo "Safety Hooks Test Suite"
echo "========================================${NC}"
echo ""
echo "Plugin root: $PLUGIN_ROOT"
echo ""

# Check dependencies
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: python3 not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Dependencies found"
echo ""

TEST_FILES=(
    "$SCRIPT_DIR/test_config.sh"
    "$SCRIPT_DIR/test_git_add.sh"
    "$SCRIPT_DIR/test_git_checkout.sh"
    "$SCRIPT_DIR/test_git_commit.sh"
    "$SCRIPT_DIR/test_git_push_pull.sh"
    "$SCRIPT_DIR/test_env_protection.sh"
    "$SCRIPT_DIR/test_file_length.sh"
    "$SCRIPT_DIR/test_rm_block.sh"
)

PASSED_TESTS=()
FAILED_TESTS=()

# Python script to parse test summary
_PARSE_SUMMARY="
import sys
import re

# Remove ANSI color codes
output = sys.stdin.read()
ansi_escape = re.compile(r'\x1b\[[0-9;]*m')
output = ansi_escape.sub('', output)

# Extract Total, Passed, Failed from output
total_match = re.search(r'Total:\s+(\d+)', output)
passed_match = re.search(r'Passed:\s+(\d+)', output)
failed_match = re.search(r'Failed:\s+(\d+)', output)

total = int(total_match.group(1)) if total_match else 0
passed = int(passed_match.group(1)) if passed_match else 0
failed = int(failed_match.group(1)) if failed_match else 0

print(f'{total},{passed},{failed}')
"

for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        # Run test and capture output
        TEST_OUTPUT=$(bash "$test_file" 2>&1)
        TEST_EXIT_CODE=$?

        # Parse summary using Python
        SUMMARY=$(echo "$TEST_OUTPUT" | python3 -c "$_PARSE_SUMMARY")
        IFS=',' read -r SUMMARY_RUN SUMMARY_PASSED SUMMARY_FAILED <<< "$SUMMARY"

        if [ -n "$SUMMARY_RUN" ]; then
            TOTAL_RUN=$((TOTAL_RUN + SUMMARY_RUN))
        fi
        if [ -n "$SUMMARY_PASSED" ]; then
            TOTAL_PASSED=$((TOTAL_PASSED + SUMMARY_PASSED))
        fi
        if [ -n "$SUMMARY_FAILED" ]; then
            TOTAL_FAILED=$((TOTAL_FAILED + SUMMARY_FAILED))
        fi

        # Track pass/fail per test file
        TEST_NAME=$(basename "$test_file")
        if [ "$TEST_EXIT_CODE" -eq 0 ]; then
            PASSED_TESTS+=("$TEST_NAME")
        else
            FAILED_TESTS+=("$TEST_NAME")
        fi

        echo "$TEST_OUTPUT" | tail -n 10
    else
        echo -e "${RED}Warning: $test_file not found${NC}"
    fi
done

# Print overall summary
echo ""
echo -e "${BLUE}========================================"
echo "Overall Test Summary"
echo "========================================${NC}"
echo "  Total:   $TOTAL_RUN"
echo -e "  ${GREEN}Passed:${NC}  $TOTAL_PASSED"
if [ "$TOTAL_FAILED" -gt 0 ]; then
    echo -e "  ${RED}Failed:${NC}  $TOTAL_FAILED"
else
    echo "  Failed:  $TOTAL_FAILED"
fi
echo "========================================"
echo ""

# List passed test files
if [ ${#PASSED_TESTS[@]} -gt 0 ]; then
    echo -e "${GREEN}Passed test files:${NC}"
    for test in "${PASSED_TESTS[@]}"; do
        echo "  ✓ $test"
    done
    echo ""
fi

# List failed test files
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo -e "${RED}Failed test files:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  ✗ $test"
    done
    echo ""
    exit 1
fi

exit 0
