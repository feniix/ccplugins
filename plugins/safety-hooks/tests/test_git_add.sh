#!/bin/bash
# Test git_add_block hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

HOOK_SCRIPT="$HOOKS_DIR/git_add_block_hook.py"

test_git_add_wildcard_blocked() {
    test_header "Git Add: Wildcard pattern blocked"

    local input
    input=$(make_hook_input "Bash" "git add *.py")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "Script executes successfully"
    assert_json_value "$output" "decision" "block" "Wildcard should be blocked"
    assert_contains "$output" "BLOCKED" "Output should contain block reason"
}

test_git_add_dot_blocked() {
    test_header "Git Add: 'git add .' blocked"

    local input
    input=$(make_hook_input "Bash" "git add .")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "'git add .' should be blocked"
}

test_git_add_dash_A_blocked() {
    test_header "Git Add: 'git add -A' blocked"

    local input
    input=$(make_hook_input "Bash" "git add -A")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "'git add -A' should be blocked"
}

test_git_add_specific_file_allowed() {
    test_header "Git Add: Specific file allowed (no block)"

    local input
    input=$(make_hook_input "Bash" "git add file.py")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    # Should return approve (not blocked, though may ask for modified files)
    local decision
    decision=$(echo "$output" | jq -r '.decision // empty')

    if [ "$decision" = "block" ]; then
        echo -e "${RED}✗${NC} Specific file should not be blocked (got: $decision)"
        ((TESTS_FAILED++))
    else
        echo -e "${GREEN}✓${NC} Specific file not blocked (decision: $decision)"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
}

test_git_add_non_git_command_ignored() {
    test_header "Git Add: Non-git command ignored"

    local input
    input=$(make_hook_input "Bash" "ls -la")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "Non-git commands should be approved"
}

test_git_add_with_dry_run_allowed() {
    test_header "Git Add: --dry-run flag always allowed"

    local input
    input=$(make_hook_input "Bash" "git add --dry-run *")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "--dry-run should be allowed"
}

run_git_add_tests() {
    check_dependencies || exit 1

    reset_counters
    test_git_add_wildcard_blocked
    test_git_add_dot_blocked
    test_git_add_dash_A_blocked
    test_git_add_specific_file_allowed
    test_git_add_non_git_command_ignored
    test_git_add_with_dry_run_allowed

    print_summary
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_git_add_tests
fi
