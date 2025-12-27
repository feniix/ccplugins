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

test_gitignore_entries_added() {
    test_header "RM Block: .gitignore entries added in git repo"

    # Create temp git repo
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || return 1
    git init -q

    # Trigger the hook with cwd set
    local input
    input=$(python3 <<PYTHON_EOF
import json
print(json.dumps({
    'session_id': 'test-session-123',
    'transcript_path': '/tmp/transcript.txt',
    'cwd': '$tmp_dir',
    'permission_mode': 'ask',
    'hook_event_name': 'PreToolUse',
    'tool_name': 'Bash',
    'tool_input': {'command': 'rm file.txt'}
}))
PYTHON_EOF
)

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    # Check .gitignore was created with entries
    if [ ! -f "$tmp_dir/.gitignore" ]; then
        echo -e "${RED}✗${NC} .gitignore was not created"
        ((TESTS_FAILED++))
        ((TESTS_RUN++))
        cd - > /dev/null
        rm -rf "$tmp_dir"
        return 1
    fi

    local content
    content=$(cat "$tmp_dir/.gitignore")

    ((TESTS_RUN++))
    if echo "$content" | grep -q "TRASH/"; then
        echo -e "${GREEN}✓${NC} TRASH/ added to .gitignore"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} TRASH/ not found in .gitignore"
        ((TESTS_FAILED++))
    fi

    ((TESTS_RUN++))
    if echo "$content" | grep -q "TRASH-FILES.md"; then
        echo -e "${GREEN}✓${NC} TRASH-FILES.md added to .gitignore"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} TRASH-FILES.md not found in .gitignore"
        ((TESTS_FAILED++))
    fi

    cd - > /dev/null
    rm -rf "$tmp_dir"
}

test_gitignore_no_duplicates() {
    test_header "RM Block: .gitignore entries not duplicated"

    # Create temp git repo with existing entries
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || return 1
    git init -q
    echo "TRASH/" > .gitignore
    echo "TRASH-FILES.md" >> .gitignore

    local original_content
    original_content=$(cat "$tmp_dir/.gitignore")

    # Trigger the hook
    local input
    input=$(python3 <<PYTHON_EOF
import json
print(json.dumps({
    'session_id': 'test-session-123',
    'transcript_path': '/tmp/transcript.txt',
    'cwd': '$tmp_dir',
    'permission_mode': 'ask',
    'hook_event_name': 'PreToolUse',
    'tool_name': 'Bash',
    'tool_input': {'command': 'rm file.txt'}
}))
PYTHON_EOF
)

    echo "$input" | python3 "$HOOK_SCRIPT" > /dev/null 2>&1

    local new_content
    new_content=$(cat "$tmp_dir/.gitignore")

    ((TESTS_RUN++))
    if [ "$original_content" = "$new_content" ]; then
        echo -e "${GREEN}✓${NC} No duplicate entries added"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Content changed when it shouldn't"
        echo "Original: $original_content"
        echo "New: $new_content"
        ((TESTS_FAILED++))
    fi

    cd - > /dev/null
    rm -rf "$tmp_dir"
}

test_gitignore_from_subdirectory() {
    test_header "RM Block: .gitignore entries added to repo root from subdir"

    # Create temp git repo
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || return 1
    git init -q
    mkdir -p subdir/deep

    # Trigger hook from subdirectory
    local input
    input=$(python3 <<PYTHON_EOF
import json
print(json.dumps({
    'session_id': 'test-session-123',
    'transcript_path': '/tmp/transcript.txt',
    'cwd': '$tmp_dir/subdir/deep',
    'permission_mode': 'ask',
    'hook_event_name': 'PreToolUse',
    'tool_name': 'Bash',
    'tool_input': {'command': 'rm file.txt'}
}))
PYTHON_EOF
)

    echo "$input" | python3 "$HOOK_SCRIPT" > /dev/null 2>&1

    # .gitignore should be at root, not in subdir
    ((TESTS_RUN++))
    if [ -f "$tmp_dir/.gitignore" ] && [ ! -f "$tmp_dir/subdir/.gitignore" ] && [ ! -f "$tmp_dir/subdir/deep/.gitignore" ]; then
        echo -e "${GREEN}✓${NC} .gitignore created at repo root, not subdirectory"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} .gitignore in wrong location"
        ((TESTS_FAILED++))
    fi

    ((TESTS_RUN++))
    if grep -q "TRASH/" "$tmp_dir/.gitignore"; then
        echo -e "${GREEN}✓${NC} TRASH/ found in root .gitignore"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} TRASH/ not in root .gitignore"
        ((TESTS_FAILED++))
    fi

    cd - > /dev/null
    rm -rf "$tmp_dir"
}

test_gitignore_not_added_outside_git() {
    test_header "RM Block: .gitignore not created outside git repo"

    # Create temp directory without git
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || return 1

    # Trigger the hook
    local input
    input=$(python3 <<PYTHON_EOF
import json
print(json.dumps({
    'session_id': 'test-session-123',
    'transcript_path': '/tmp/transcript.txt',
    'cwd': '$tmp_dir',
    'permission_mode': 'ask',
    'hook_event_name': 'PreToolUse',
    'tool_name': 'Bash',
    'tool_input': {'command': 'rm file.txt'}
}))
PYTHON_EOF
)

    echo "$input" | python3 "$HOOK_SCRIPT" > /dev/null 2>&1

    # .gitignore should NOT be created
    ((TESTS_RUN++))
    if [ ! -f "$tmp_dir/.gitignore" ]; then
        echo -e "${GREEN}✓${NC} .gitignore not created outside git repo"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} .gitignore was created outside git repo"
        ((TESTS_FAILED++))
    fi

    cd - > /dev/null
    rm -rf "$tmp_dir"
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
    test_gitignore_entries_added
    test_gitignore_no_duplicates
    test_gitignore_from_subdirectory
    test_gitignore_not_added_outside_git

    print_summary
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_rm_block_tests
fi
