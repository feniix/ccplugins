#!/bin/bash
# Test config module (simplified - basic import check)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

test_config_module_imports() {
    test_header "Config: Module imports successfully"

    local output
    output=$(python3 -c "import sys; sys.path.insert(0, '$HOOKS_DIR'); from config import get_config; print('OK')" 2>&1)

    assert_contains "$output" "OK" "Config module should import"
}

test_config_default_values() {
    test_header "Config: Default values are set"

    local output
    output=$(python3 -c "
import sys
sys.path.insert(0, '$HOOKS_DIR')
from config import get_config
c = get_config()
print(f'rm:{c.rm_block_enabled}')
print(f'max_lines:{c.file_max_lines}')
" 2>&1)

    assert_contains "$output" "rm:True" "RM block enabled by default"
    assert_contains "$output" "max_lines:10000" "Default max lines is 10000"
}

test_config_extensions_list() {
    test_header "Config: Source code extensions defined"

    local output
    output=$(python3 -c "
import sys
sys.path.insert(0, '$HOOKS_DIR')
from config import DEFAULT_SOURCE_CODE_EXTENSIONS
print(f'count:{len(DEFAULT_SOURCE_CODE_EXTENSIONS)}')
print(f'has_py:{'.py' in DEFAULT_SOURCE_CODE_EXTENSIONS}')
" 2>&1)

    assert_contains "$output" "has_py:True" "Extensions list includes .py"
}

run_config_tests() {
    check_dependencies || exit 1

    reset_counters
    test_config_module_imports
    test_config_default_values
    test_config_extensions_list

    print_summary
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_config_tests
fi
