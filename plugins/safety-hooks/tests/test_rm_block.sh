#!/bin/bash
# Test rm_block hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

HOOK_SCRIPT="$HOOKS_DIR/rm_block_hook.py"

test_rm_command_blocked() {
    test_header "RM Block: Basic 'rm' command blocked"

    local input
    input=$(make_hook_input "Bash" "rm file.txt")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "'rm' command should be blocked"
    assert_contains "$output" "TRASH" "Output should mention TRASH directory"
}

test_rm_recursive_blocked() {
    test_header "RM Block: 'rm -rf' blocked"

    local input
    input=$(make_hook_input "Bash" "rm -rf dir/")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "'rm -rf' should be blocked"
}

test_rm_with_path_blocked() {
    test_header "RM Block: 'rm' with path blocked"

    local input
    input=$(make_hook_input "Bash" "/bin/rm file.txt")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "'/bin/rm' should be blocked"
}

test_non_rm_command_allowed() {
    test_header "RM Block: Non-rm commands allowed"

    local input
    input=$(make_hook_input "Bash" "ls -la")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "Non-rm commands should be approved"
}

test_trash_command_allowed() {
    test_header "RM Block: 'trash' command allowed"

    local input
    input=$(make_hook_input "Bash" "trash file.txt")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "'trash' command should be approved"
}

test_grep_rm_not_blocked() {
    test_header "RM Block: Commands containing 'rm' as substring not blocked"

    local input
    input=$(make_hook_input "Bash" "grep 'pattern' file.txt")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "'grep' should not be blocked"
}

run_rm_block_tests() {
    check_dependencies || exit 1

    reset_counters
    test_rm_command_blocked
    test_rm_recursive_blocked
    test_rm_with_path_blocked
    test_non_rm_command_allowed
    test_trash_command_allowed
    test_grep_rm_not_blocked

    print_summary
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_rm_block_tests
fi
