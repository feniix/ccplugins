#!/bin/bash
# Test git_commit_block hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

HOOK_SCRIPT="$HOOKS_DIR/git_commit_block_hook.py"

# Helper to get decision from output (handles both flat and nested formats)
_get_decision() {
    local output="$1"
    echo "$output" | python3 -c "
import json
import sys

try:
    data = json.loads(sys.stdin.read())
    # Check nested format (git_commit_block uses this)
    if 'hookSpecificOutput' in data:
        nested = data['hookSpecificOutput']
        if 'permissionDecision' in nested:
            print(nested['permissionDecision'])
    # Check flat format
    elif 'decision' in data:
        print(data['decision'])
    else:
        print('')
except:
    print('')
"
}

test_git_commit_should_ask() {
    test_header "Git Commit: 'git commit' should ask for approval"

    local input
    input=$(make_hook_input "Bash" "git commit -m 'feat: add feature'")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} 'git commit' should ask for approval"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 'git commit' should ask for approval (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_git_commit_without_message_should_ask() {
    test_header "Git Commit: 'git commit' without message should ask"

    local input
    input=$(make_hook_input "Bash" "git commit")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} 'git commit' without message should ask"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 'git commit' without message should ask (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_git_commit_amend_should_ask() {
    test_header "Git Commit: 'git commit --amend' should ask"

    local input
    input=$(make_hook_input "Bash" "git commit --amend")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} 'git commit --amend' should ask"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 'git commit --amend' should ask (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_non_git_commit_allowed() {
    test_header "Git Commit: Non-git commands allowed"

    local input
    input=$(make_hook_input "Bash" "git status")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "'git status' should be approved"
}

test_git_checkout_not_affected() {
    test_header "Git Commit: 'git checkout' not affected by commit hook"

    local input
    input=$(make_hook_input "Bash" "git checkout main")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "'git checkout' should be approved"
}

test_compound_git_commit_detected() {
    test_header "Git Commit: Git commit in compound command detected"

    local input
    input=$(make_hook_input "Bash" "git add . && git commit -m 'changes'")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} Git commit in compound command detected (decision: ask)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Git commit in compound command should be detected (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

run_git_commit_tests() {
    check_dependencies || exit 1

    reset_counters
    test_git_commit_should_ask
    test_git_commit_without_message_should_ask
    test_git_commit_amend_should_ask
    test_non_git_commit_allowed
    test_git_checkout_not_affected
    test_compound_git_commit_detected

    print_summary
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_git_commit_tests
fi
