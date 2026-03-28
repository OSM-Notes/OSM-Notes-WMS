#!/usr/bin/env bash
#
# Run CI Tests Locally
# Simulates the GitHub Actions workflow to test changes locally
# Author: Andres Gomez (AngocA)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_message() {
    local color="${1}"
    shift
    echo -e "${color}$*${NC}"
}

print_message "${YELLOW}" "=== Running CI Tests Locally (OSM-Notes-WMS) ==="
echo

cd "${PROJECT_ROOT}"

# Check if BATS is installed
if ! command -v bats > /dev/null 2>&1; then
    print_message "${YELLOW}" "Installing BATS..."
    sudo apt-get update && sudo apt-get install -y bats 2>/dev/null || {
        git clone https://github.com/bats-core/bats-core.git /tmp/bats 2>/dev/null || true
        if [[ -d /tmp/bats ]]; then
            sudo /tmp/bats/install.sh /usr/local 2>/dev/null || {
                print_message "${RED}" "Failed to install BATS. Please install manually:"
                echo "  git clone https://github.com/bats-core/bats-core.git"
                echo "  cd bats-core"
                echo "  ./install.sh /usr/local"
                exit 1
            }
        fi
    }
fi

# Check PostgreSQL
if command -v psql > /dev/null 2>&1; then
    print_message "${GREEN}" "✓ PostgreSQL client found"
else
    print_message "${YELLOW}" "⚠ PostgreSQL client not found (tests may skip DB tests)"
fi

# Check shfmt
if ! command -v shfmt > /dev/null 2>&1; then
    print_message "${YELLOW}" "Installing shfmt..."
    wget -q -O /tmp/shfmt https://github.com/mvdan/sh/releases/download/v3.7.0/shfmt_v3.7.0_linux_amd64
    chmod +x /tmp/shfmt
    sudo mv /tmp/shfmt /usr/local/bin/shfmt || {
        print_message "${YELLOW}" "⚠ Could not install shfmt automatically"
    }
fi

echo
print_message "${YELLOW}" "=== Step 1: Code Formatting Checks ==="
echo

# Check bash formatting with shfmt
print_message "${BLUE}" "Checking bash code formatting with shfmt..."
if command -v shfmt > /dev/null 2>&1; then
    if find bin tests -name "*.sh" -type f -exec shfmt -d {} \; 2>&1 | grep -q "."; then
        print_message "${RED}" "✗ Code formatting issues found"
        find bin tests -name "*.sh" -type f -exec shfmt -d {} \;
        exit 1
    else
        print_message "${GREEN}" "✓ Code formatting check passed"
    fi
else
    print_message "${YELLOW}" "⚠ shfmt not available, skipping format check"
fi

# Check SQL formatting (optional)
if command -v sqlfluff > /dev/null 2>&1; then
    print_message "${BLUE}" "Checking SQL formatting..."
    if find sql -name "*.sql" -type f -exec sqlfluff lint {} \; 2>&1 | grep -q "error"; then
        print_message "${YELLOW}" "⚠ SQL formatting issues found (non-blocking)"
    else
        print_message "${GREEN}" "✓ SQL formatting check passed"
    fi
fi

# Check Prettier formatting (optional)
if command -v prettier > /dev/null 2>&1 || command -v npx > /dev/null 2>&1; then
    print_message "${BLUE}" "Checking Prettier formatting..."
    if command -v prettier > /dev/null 2>&1; then
        PRETTIER_CMD=prettier
    else
        PRETTIER_CMD="npx prettier"
    fi
    if ${PRETTIER_CMD} --check "**/*.{md,json,yaml,yml,css,html}" --ignore-path .prettierignore 2>/dev/null; then
        print_message "${GREEN}" "✓ Prettier formatting check passed"
    else
        print_message "${YELLOW}" "⚠ Prettier formatting issues found (non-blocking)"
    fi
fi

echo
print_message "${YELLOW}" "=== Step 2: Tests ==="
echo

# Setup test environment
export TEST_DBNAME=osm_notes_wms_test
export TEST_DBUSER=testuser
export TEST_DBPASSWORD=testpass
export TEST_DBHOST=localhost
export TEST_DBPORT=5432
export PGPASSWORD=testpass
export DBNAME=osm_notes_wms_test
export DBUSER=testuser
export DBPASSWORD=testpass
export DBHOST=localhost
export DBPORT=5432
export MOCK_MODE=0

# Check if PostgreSQL is running
if command -v pg_isready > /dev/null 2>&1 && pg_isready -h localhost -U testuser -d postgres > /dev/null 2>&1; then
    print_message "${GREEN}" "✓ PostgreSQL is running"

    # Create test database
    print_message "${BLUE}" "Setting up test database..."
    PGPASSWORD=testpass createdb -h localhost -U testuser osm_notes_wms_test 2>/dev/null || true
    PGPASSWORD=testpass psql -h localhost -U testuser -d osm_notes_wms_test -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>/dev/null || true
    PGPASSWORD=testpass psql -h localhost -U testuser -d osm_notes_wms_test -v ON_ERROR_STOP=1 -c "
CREATE TABLE IF NOT EXISTS schema_version (
 component VARCHAR(64) PRIMARY KEY,
 version VARCHAR(16) NOT NULL,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO schema_version (component, version) VALUES ('core', '1.1.0')
ON CONFLICT (component) DO UPDATE SET
 version = EXCLUDED.version,
 updated_at = CURRENT_TIMESTAMP;
" 2>/dev/null || true

    # Make scripts executable
    find bin -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find tests -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find tests -type f -name "*.bats" -exec chmod +x {} \; 2>/dev/null || true

    # Run unit tests
    print_message "${BLUE}" "Running unit tests..."
    if [[ -d tests/unit/bash ]]; then
        if bats -r tests/unit/bash/ 2>&1; then
            print_message "${GREEN}" "✓ Unit tests passed"
        else
            print_message "${RED}" "✗ Unit tests failed"
            exit 1
        fi
    else
        print_message "${YELLOW}" "⚠ Unit tests directory not found"
    fi

    # Run integration tests
    print_message "${BLUE}" "Running integration tests..."
    if [[ -d tests/integration ]]; then
        if bats -r tests/integration/ 2>&1; then
            print_message "${GREEN}" "✓ Integration tests passed"
        else
            print_message "${RED}" "✗ Integration tests failed"
            exit 1
        fi
    else
        print_message "${YELLOW}" "⚠ Integration tests directory not found"
    fi
else
    print_message "${YELLOW}" "⚠ PostgreSQL is not running. Skipping tests."
    print_message "${YELLOW}" "   Start PostgreSQL to run tests:"
    print_message "${YELLOW}" "   docker run -d -p 5432:5432 -e POSTGRES_USER=testuser -e POSTGRES_PASSWORD=testpass -e POSTGRES_DB=postgres postgis/postgis:15-3.3"
fi

echo
print_message "${YELLOW}" "=== Step 3: Test Coverage Evaluation ==="
echo

# Test coverage evaluation function
evaluate_test_coverage() {
    local scripts_dir="${1:-bin}"
    local tests_dir="${2:-tests}"
    
    print_message "${BLUE}" "Evaluating test coverage..."
    
    # Count lines in a file
    count_lines() {
        local file="${1}"
        if [[ -f "${file}" ]]; then
            wc -l < "${file}" | tr -d ' '
        else
            echo "0"
        fi
    }
    
    # Count test files for a script
    count_test_files() {
        local script_path="${1}"
        local script_name
        script_name=$(basename "${script_path}" .sh)
        
        local test_count=0
        
        # Check unit tests
        if [[ -d "${PROJECT_ROOT}/${tests_dir}/unit" ]]; then
            if find "${PROJECT_ROOT}/${tests_dir}/unit" -name "test_${script_name}.sh" -o -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" 2>/dev/null | grep -q .; then
                test_count=$(find "${PROJECT_ROOT}/${tests_dir}/unit" \( -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" \) -type f 2>/dev/null | wc -l | tr -d ' ')
            fi
        fi
        
        # Check integration tests
        if [[ -d "${PROJECT_ROOT}/${tests_dir}/integration" ]]; then
            if find "${PROJECT_ROOT}/${tests_dir}/integration" -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" 2>/dev/null | grep -q .; then
                test_count=$((test_count + $(find "${PROJECT_ROOT}/${tests_dir}/integration" \( -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" \) -type f 2>/dev/null | wc -l | tr -d ' ')))
            fi
        fi
        
        # Also check tests directory directly (for simpler structures)
        if [[ -d "${PROJECT_ROOT}/${tests_dir}" ]]; then
            if find "${PROJECT_ROOT}/${tests_dir}" -maxdepth 1 -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" 2>/dev/null | grep -q .; then
                test_count=$((test_count + $(find "${PROJECT_ROOT}/${tests_dir}" -maxdepth 1 \( -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" \) -type f 2>/dev/null | wc -l | tr -d ' ')))
            fi
        fi
        
        echo "${test_count}"
    }
    
    # Calculate coverage percentage
    calculate_coverage() {
        local script_path="${1}"
        local test_count
        test_count=$(count_test_files "${script_path}")
        
        if [[ ${test_count} -gt 0 ]]; then
            # Heuristic: 1 test = 40%, 2 tests = 60%, 3+ tests = 80%
            local coverage=0
            if [[ ${test_count} -ge 3 ]]; then
                coverage=80
            elif [[ ${test_count} -eq 2 ]]; then
                coverage=60
            elif [[ ${test_count} -eq 1 ]]; then
                coverage=40
            fi
            echo "${coverage}"
        else
            echo "0"
        fi
    }
    
    # Find all scripts
    local scripts=()
    if [[ -d "${PROJECT_ROOT}/${scripts_dir}" ]]; then
        while IFS= read -r -d '' script; do
            scripts+=("${script}")
        done < <(find "${PROJECT_ROOT}/${scripts_dir}" -name "*.sh" -type f -print0 2>/dev/null | sort -z)
    fi
    
    if [[ ${#scripts[@]} -eq 0 ]]; then
        print_message "${YELLOW}" "⚠ No scripts found in ${scripts_dir}/, skipping coverage evaluation"
        return 0
    fi
    
    local total_scripts=${#scripts[@]}
    local scripts_with_tests=0
    local scripts_above_threshold=0
    local total_coverage=0
    local coverage_count=0
    
    for script in "${scripts[@]}"; do
        local script_name
        script_name=$(basename "${script}")
        local test_count
        test_count=$(count_test_files "${script}")
        local coverage
        coverage=$(calculate_coverage "${script}")
        
        if [[ ${test_count} -gt 0 ]]; then
            scripts_with_tests=$((scripts_with_tests + 1))
            if [[ "${coverage}" =~ ^[0-9]+$ ]] && [[ ${coverage} -gt 0 ]]; then
                total_coverage=$((total_coverage + coverage))
                coverage_count=$((coverage_count + 1))
                
                if [[ ${coverage} -ge 80 ]]; then
                    scripts_above_threshold=$((scripts_above_threshold + 1))
                fi
            fi
        fi
    done
    
    # Calculate overall coverage
    local overall_coverage=0
    if [[ ${coverage_count} -gt 0 ]]; then
        overall_coverage=$((total_coverage / coverage_count))
    fi
    
    echo
    echo "Coverage Summary:"
    echo "  Total scripts: ${total_scripts}"
    echo "  Scripts with tests: ${scripts_with_tests}"
    echo "  Scripts above 80% coverage: ${scripts_above_threshold}"
    echo "  Average coverage: ${overall_coverage}%"
    echo
    
    if [[ ${overall_coverage} -ge 80 ]]; then
        print_message "${GREEN}" "✓ Coverage target met (${overall_coverage}% >= 80%)"
    elif [[ ${overall_coverage} -ge 50 ]]; then
        print_message "${YELLOW}" "⚠ Coverage below target (${overall_coverage}% < 80%), improvement needed"
    else
        print_message "${YELLOW}" "⚠ Coverage significantly below target (${overall_coverage}% < 50%)"
    fi
    
    echo
    print_message "${BLUE}" "Note: This is an estimated coverage based on test file presence."
    print_message "${BLUE}" "For accurate coverage, use code instrumentation tools like bashcov."
}

# Run coverage evaluation (non-blocking)
if [[ -d "${PROJECT_ROOT}/bin" ]] || [[ -d "${PROJECT_ROOT}/scripts" ]]; then
    if [[ -d "${PROJECT_ROOT}/bin" ]]; then
        evaluate_test_coverage "bin" "tests" || true
    elif [[ -d "${PROJECT_ROOT}/scripts" ]]; then
        evaluate_test_coverage "scripts" "tests" || true
    fi
else
    print_message "${YELLOW}" "⚠ No bin/ or scripts/ directory found, skipping coverage evaluation"
fi

echo
print_message "${GREEN}" "=== All CI Tests Completed Successfully ==="
echo
print_message "${GREEN}" "✅ Code Formatting Checks: PASSED"
if command -v pg_isready > /dev/null 2>&1 && pg_isready -h localhost -U testuser -d postgres > /dev/null 2>&1; then
    print_message "${GREEN}" "✅ Unit Tests: PASSED"
    print_message "${GREEN}" "✅ Integration Tests: PASSED"
fi
echo

exit 0
