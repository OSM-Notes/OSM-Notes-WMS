#!/bin/bash

# Validates consumer schema contracts against the target schema version.
#
# Author: Andres Gomez (AngocA)
# Version: 2026-03-28

set -euo pipefail

declare ROOT_DIR
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly ROOT_DIR
declare -r COMMON_FUNCTIONS_FILE="${ROOT_DIR}/lib/osm-common/commonFunctions.sh"

export SCRIPT_BASE_DIRECTORY="${ROOT_DIR}"

function main() {
 if [[ ! -f "${COMMON_FUNCTIONS_FILE}" ]]; then
  echo "ERROR: Missing file ${COMMON_FUNCTIONS_FILE}" >&2
  exit 1
 fi

 # shellcheck disable=SC1090
 source "${COMMON_FUNCTIONS_FILE}"

 local TARGET_VERSION="${SCHEMA_CONTRACT_TARGET_VERSION:-}"
 if [[ -z "${TARGET_VERSION}" ]]; then
  echo "ERROR: SCHEMA_CONTRACT_TARGET_VERSION is not set (etc/schema_compatibility.sh)" >&2
  exit 1
 fi
 echo "Target schema version: ${TARGET_VERSION}"

 local EXIT_CODE=0
 local CONSUMER
 for CONSUMER in ingestion api wms analytics monitoring; do
  local VALIDATION_EXIT_CODE=0
  # shellcheck disable=SC2310
  __validate_schema_contract_target "${CONSUMER}" "${TARGET_VERSION}" \
   || VALIDATION_EXIT_CODE=$?
  if [[ "${VALIDATION_EXIT_CODE}" -ne 0 ]]; then
   EXIT_CODE=1
  fi
 done

 if [[ "${EXIT_CODE}" -ne 0 ]]; then
  echo "Schema contract validation failed." >&2
  exit "${EXIT_CODE}"
 fi
 echo "Schema contract validation passed."
}

main "$@"
