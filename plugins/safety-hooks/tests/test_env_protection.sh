#!/bin/bash
# Test env_file_protection hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

HOOK_SCRIPT="$HOOKS_DIR/env_file_protection_hook.py"

test_cat_env_file_blocked() {
    test_header "Env Protection: 'cat .env' blocked"

    local input
    input=$(make_hook_input "Bash" "cat .env")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "'cat .env' should be blocked"
}

test_write_to_env_blocked() {
    test_header "Env Protection: Writing to .env blocked"

    local input
    input=$(make_hook_input "Bash" "echo 'KEY=value' > .env")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "Writing to .env should be blocked"
}

test_env_local_blocked() {
    test_header "Env Protection: 'cat .env.local' blocked"

    local input
    input=$(make_hook_input "Bash" "cat .env.local")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "'cat .env.local' should be blocked"
}

test_grep_env_blocked() {
    test_header "Env Protection: 'grep' on .env blocked"

    local input
    input=$(make_hook_input "Bash" "grep 'API_KEY' .env")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "'grep .env' should be blocked"
}

test_normal_command_allowed() {
    test_header "Env Protection: Normal commands allowed"

    local input
    input=$(make_hook_input "Bash" "cat config.py")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "approve" "Normal commands should be approved"
}

test_editor_env_blocked() {
    test_header "Env Protection: Opening .env in editor blocked"

    local input
    input=$(make_hook_input "Bash" "nano .env")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    assert_json_value "$output" "decision" "block" "Opening .env in editor should be blocked"
}

run_env_protection_tests() {
    check_dependencies || exit 1

    reset_counters
    test_cat_env_file_blocked
    test_write_to_env_blocked
    test_env_local_blocked
    test_grep_env_blocked
    test_normal_command_allowed
    test_editor_env_blocked

    print_summary
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_env_protection_tests
fi
