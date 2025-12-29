#!/bin/bash
# Test git_push_pull_ask hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

HOOK_SCRIPT="$HOOKS_DIR/git_push_pull_ask_hook.py"

# Helper to get decision from output (handles both flat and nested formats)
_get_decision() {
    local output="$1"
    echo "$output" | python3 -c "
import json
import sys

try:
    data = json.loads(sys.stdin.read())
    # Check nested format (git_push_pull uses this)
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

test_git_push_should_ask() {
    test_header "Git Push/Pull: 'git push' should ask for approval"

    local input
    input=$(make_hook_input "Bash" "git push origin main")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} 'git push' should ask for approval"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 'git push' should ask for approval (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_git_push_without_remote_should_ask() {
    test_header "Git Push/Pull: 'git push' without remote should ask"

    local input
    input=$(make_hook_input "Bash" "git push")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} 'git push' without remote should ask"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 'git push' without remote should ask (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_git_push_with_flags_should_ask() {
    test_header "Git Push/Pull: 'git push -f' should ask"

    local input
    input=$(make_hook_input "Bash" "git push -f origin main")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} 'git push -f' should ask"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 'git push -f' should ask (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_git_pull_should_ask() {
    test_header "Git Push/Pull: 'git pull' should ask for approval"

    local input
    input=$(make_hook_input "Bash" "git pull origin main")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} 'git pull' should ask for approval"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 'git pull' should ask for approval (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_git_pull_without_remote_should_ask() {
    test_header "Git Push/Pull: 'git pull' without remote should ask"

    local input
    input=$(make_hook_input "Bash" "git pull")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} 'git pull' without remote should ask"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 'git pull' without remote should ask (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_git_pull_with_flags_should_ask() {
    test_header "Git Push/Pull: 'git pull --rebase' should ask"

    local input
    input=$(make_hook_input "Bash" "git pull --rebase")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} 'git pull --rebase' should ask"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} 'git pull --rebase' should ask (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_non_git_commands_allowed() {
    test_header "Git Push/Pull: Non-git commands allowed"

    local input
    input=$(make_hook_input "Bash" "git status")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "'git status' should be approved"
}

test_git_commit_not_affected() {
    test_header "Git Push/Pull: 'git commit' not affected by push/pull hook"

    local input
    input=$(make_hook_input "Bash" "git commit -m 'message'")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "'git commit' should be approved"
}

test_compound_git_push_detected() {
    test_header "Git Push/Pull: Git push in compound command detected"

    local input
    input=$(make_hook_input "Bash" "git add . && git push")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} Git push in compound command detected (decision: ask)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Git push in compound command should be detected (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_compound_git_pull_detected() {
    test_header "Git Push/Pull: Git pull in compound command detected"

    local input
    input=$(make_hook_input "Bash" "git stash && git pull && git stash pop")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} Git pull in compound command detected (decision: ask)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Git pull in compound command should be detected (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

run_git_push_pull_tests() {
    check_dependencies || exit 1

    reset_counters
    test_git_push_should_ask
    test_git_push_without_remote_should_ask
    test_git_push_with_flags_should_ask
    test_git_pull_should_ask
    test_git_pull_without_remote_should_ask
    test_git_pull_with_flags_should_ask
    test_non_git_commands_allowed
    test_git_commit_not_affected
    test_compound_git_push_detected
    test_compound_git_pull_detected

    print_summary
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_git_push_pull_tests
fi
