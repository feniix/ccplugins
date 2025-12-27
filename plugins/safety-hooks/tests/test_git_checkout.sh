#!/bin/bash
# Test git_checkout_safety hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

HOOK_SCRIPT="$HOOKS_DIR/git_checkout_safety_hook.py"

test_git_checkout_force_blocked() {
    test_header "Git Checkout: Force flag blocked"

    local input
    input=$(make_hook_input "Bash" "git checkout -f")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "'git checkout -f' should be blocked"
    assert_contains "$output" "DANGEROUS" "Output should contain danger warning"
}

test_git_checkout_dot_blocked() {
    test_header "Git Checkout: 'git checkout .' blocked with changes"

    # Mock git status to return changes
    local input
    input=$(make_hook_input "Bash" "git checkout .")

    # This test requires mocking subprocess, which is complex in pure bash
    # For now, test the pattern matching works
    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    # Should at least not approve without checking git status
    local decision
    decision=$(echo "$output" | jq -r '.decision // empty')

    if [ "$decision" = "approve" ]; then
        echo -e "${RED}✗${NC} 'git checkout .' should require approval"
        ((TESTS_FAILED++))
    else
        echo -e "${GREEN}✓${NC} 'git checkout .' handled appropriately"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
}

test_git_checkout_new_branch_allowed() {
    test_header "Git Checkout: New branch creation allowed"

    local input
    input=$(make_hook_input "Bash" "git checkout -b feature-branch")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "'git checkout -b' should be approved"
}

test_git_checkout_help_allowed() {
    test_header "Git Checkout: Help flag allowed"

    local input
    input=$(make_hook_input "Bash" "git checkout --help")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "'git checkout --help' should be approved"
}

test_git_checkout_non_git_ignored() {
    test_header "Git Checkout: Non-git command ignored"

    local input
    input=$(make_hook_input "Bash" "echo hello")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "Non-git commands should be approved"
}

run_git_checkout_tests() {
    check_dependencies || exit 1

    reset_counters
    test_git_checkout_force_blocked
    test_git_checkout_dot_blocked
    test_git_checkout_new_branch_allowed
    test_git_checkout_help_allowed
    test_git_checkout_non_git_ignored

    print_summary
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_git_checkout_tests
fi
