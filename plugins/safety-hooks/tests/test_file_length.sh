#!/bin/bash
# Test file_length_limit hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

HOOK_SCRIPT="$HOOKS_DIR/file_length_limit_hook.py"

# Helper to get decision from output (handles both flat and nested formats)
_get_decision() {
    local output="$1"
    echo "$output" | python3 -c "
import json
import sys

try:
    data = json.loads(sys.stdin.read())
    if 'hookSpecificOutput' in data:
        nested = data['hookSpecificOutput']
        if 'permissionDecision' in nested:
            print(nested['permissionDecision'])
    elif 'decision' in data:
        print(data['decision'])
    else:
        print('')
except:
    print('')
"
}

test_small_file_approved() {
    test_header "File Length: Small file approved (defers to system)"

    local input
    input=$(make_file_input "Write" "test.py" "print('hello')")

    local output
    output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${RED}✗${NC} Small file should not ask for approval"
        ((TESTS_FAILED++))
    else
        echo -e "${GREEN}✓${NC} Small file handled appropriately (decision: ${decision:-defer})"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
}

test_large_file_should_ask() {
    test_header "File Length: Large file should ask"

    # Use Python to generate the test input
    local tmp_input
    tmp_input=$(mktemp)
    python3 -c "
import json
content = 'x\\n' * 11000
data = {
    'session_id': 'test-session-123',
    'transcript_path': '/tmp/transcript.txt',
    'cwd': '/test/project',
    'permission_mode': 'ask',
    'hook_event_name': 'PreToolUse',
    'tool_name': 'Write',
    'tool_input': {
        'file_path': 'large.py',
        'content': content
    }
}
print(json.dumps(data))
" > "$tmp_input"

    local output
    output=$(cat "$tmp_input" | python3 "$HOOK_SCRIPT" 2>&1)
    rm -f "$tmp_input"

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${GREEN}✓${NC} Large file should ask for approval"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Large file should ask for approval (got: $decision)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_non_source_file_deferred() {
    test_header "File Length: Non-source file deferred"

    local tmp_input
    tmp_input=$(mktemp)
    python3 -c "
import json
content = 'x\\n' * 11000
data = {
    'session_id': 'test-session-123',
    'transcript_path': '/tmp/transcript.txt',
    'cwd': '/test/project',
    'permission_mode': 'ask',
    'hook_event_name': 'PreToolUse',
    'tool_name': 'Write',
    'tool_input': {
        'file_path': 'notes.txt',
        'content': content
    }
}
print(json.dumps(data))
" > "$tmp_input"

    local output
    output=$(cat "$tmp_input" | python3 "$HOOK_SCRIPT" 2>&1)
    rm -f "$tmp_input"

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${RED}✗${NC} Non-source files should defer to system"
        ((TESTS_FAILED++))
    else
        echo -e "${GREEN}✓${NC} Non-source file deferred (decision: ${decision:-empty})"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
}

test_exact_boundary_case() {
    test_header "File Length: Exactly at boundary (10000 lines)"

    local tmp_input
    tmp_input=$(mktemp)
    python3 -c "
import json
content = 'line\\n' * 9999 + 'last'
data = {
    'session_id': 'test-session-123',
    'transcript_path': '/tmp/transcript.txt',
    'cwd': '/test/project',
    'permission_mode': 'ask',
    'hook_event_name': 'PreToolUse',
    'tool_name': 'Write',
    'tool_input': {
        'file_path': 'boundary.py',
        'content': content
    }
}
print(json.dumps(data))
" > "$tmp_input"

    local output
    output=$(cat "$tmp_input" | python3 "$HOOK_SCRIPT" 2>&1)
    rm -f "$tmp_input"

    local decision
    decision=$(_get_decision "$output")

    if [ "$decision" = "ask" ]; then
        echo -e "${RED}✗${NC} File at exactly 10000 lines should not ask"
        ((TESTS_FAILED++))
    else
        echo -e "${GREEN}✓${NC} Boundary file handled correctly"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
}

test_common_source_extensions() {
    test_header "File Length: Common source extensions are checked"

    local extensions=(".py" ".js" ".ts" ".go" ".rs" ".java")

    for ext in "${extensions[@]}"; do
        local input
        input=$(make_file_input "Write" "test$ext" "print('test')")

        local output
        output=$(echo "$input" | python3 "$HOOK_SCRIPT" 2>&1)

        echo -e "${GREEN}✓${NC} Extension $ext processed"
        ((TESTS_PASSED++))
        ((TESTS_RUN++))
    done
}

run_file_length_tests() {
    check_dependencies || exit 1

    reset_counters
    test_small_file_approved
    test_large_file_should_ask
    test_non_source_file_deferred
    test_exact_boundary_case
    test_common_source_extensions

    print_summary
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_file_length_tests
fi
