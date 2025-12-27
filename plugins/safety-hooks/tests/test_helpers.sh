#!/bin/bash
# Test helper functions for safety-hooks tests

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Set up paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")/hooks"
export CLAUDE_PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# Add hooks to Python path for imports
export PYTHONPATH="$HOOKS_DIR:$PYTHONPATH"

# Python helper for JSON parsing
_PYTHON_JSON_HELPER="
import json
import sys

def get_json_value(json_str, key):
    try:
        data = json.loads(json_str)
        # Support both flat and nested (hookSpecificOutput) formats
        if key in data:
            return str(data[key])
        if 'hookSpecificOutput' in data:
            nested = data['hookSpecificOutput']
            if key in nested:
                return str(nested[key])
        return ''
    except:
        return ''

def has_key(json_str, key):
    try:
        data = json.loads(json_str)
        return key in data or ('hookSpecificOutput' in data and key in data['hookSpecificOutput'])
    except:
        return False

# Parse command line args
if len(sys.argv) >= 3:
    cmd = sys.argv[1]
    if cmd == 'get':
        print(get_json_value(sys.stdin.read(), sys.argv[2]))
    elif cmd == 'has':
        print(has_key(sys.stdin.read(), sys.argv[2]))
"

# Print test header
test_header() {
    echo ""
    echo "========================================"
    echo "Testing: $1"
    echo "========================================"
}

# Assert exit code equals expected value
assert_exit_code() {
    local actual=$1
    local expected=$2
    local message="${3:-Exit code should be $expected}"

    ((TESTS_RUN++))

    if [ "$actual" -eq "$expected" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message (got $actual, expected $expected)"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert string contains substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Output should contain '$needle'}"

    ((TESTS_RUN++))

    if echo "$haystack" | grep -qF "$needle"; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert JSON output contains key with value
assert_json_value() {
    local json="$1"
    local key="$2"
    local expected="$3"
    local message="${4:-JSON key '$key' should be '$expected'}"

    local actual
    actual=$(echo "$json" | python3 -c "$_PYTHON_JSON_HELPER" get "$key")

    ((TESTS_RUN++))

    if [ "$actual" = "$expected" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message (got '$actual')"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Create sample hook input JSON
make_hook_input() {
    local tool_name="${1:-Bash}"
    local command="${2:-ls}"

    python3 << EOF
import json
print(json.dumps({
    'session_id': 'test-session-123',
    'transcript_path': '/tmp/transcript.txt',
    'cwd': '/test/project',
    'permission_mode': 'ask',
    'hook_event_name': 'PreToolUse',
    'tool_name': '$tool_name',
    'tool_input': {'command': """${command}"""}
}))
EOF
}

# Make hook input with file_path
make_file_input() {
    local tool_name="${1:-Write}"
    local file_path="${2:-test.py}"
    local content="${3:-print('hello')}"

    python3 << EOF
import json
print(json.dumps({
    'session_id': 'test-session-123',
    'transcript_path': '/tmp/transcript.txt',
    'cwd': '/test/project',
    'permission_mode': 'ask',
    'hook_event_name': 'PreToolUse',
    'tool_name': '$tool_name',
    'tool_input': {'file_path': """${file_path}""", 'content': """${content}""""}
}))
EOF
}

# Print test summary
print_summary() {
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "  Total:   $TESTS_RUN"
    echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
    if [ "$TESTS_FAILED" -gt 0 ]; then
        echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
    else
        echo "  Failed:  $TESTS_FAILED"
    fi
    echo "========================================"

    if [ "$TESTS_FAILED" -gt 0 ]; then
        return 1
    fi
    return 0
}

# Reset test counters
reset_counters() {
    TESTS_RUN=0
    TESTS_PASSED=0
    TESTS_FAILED=0
}

# Check dependencies
check_dependencies() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 not found${NC}"
        return 1
    fi
    return 0
}
