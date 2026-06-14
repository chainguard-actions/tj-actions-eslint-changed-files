#!/usr/bin/env bash

set -euo pipefail

echo "::group::eslint-changed-files"

if [[ -n $INPUT_PATH ]]; then
  REPO_DIR="$GITHUB_WORKSPACE/$INPUT_PATH"

  echo "Resolving repository path: $REPO_DIR"
  if [[ ! -d "$REPO_DIR" ]]; then
    echo "::error::Invalid repository path: $REPO_DIR"
    echo "::endgroup::"
    exit 1
  fi
  cd "$REPO_DIR"
fi

TEMP_DIR=$(mktemp -d)
RD_JSON_FILE="$TEMP_DIR/rd.json"
ESLINT_FORMATTER="$TEMP_DIR/formatter.cjs"

if [[ "$INPUT_SKIP_ANNOTATIONS" != "true" ]]; then
  curl -sf -o "$ESLINT_FORMATTER" https://raw.githubusercontent.com/reviewdog/action-eslint/master/eslint-formatter-rdjson/index.js
  # shellcheck disable=SC2034
  export REVIEWDOG_GITHUB_API_TOKEN=$INPUT_TOKEN
fi

# Build CONFIG_ARG as an array to prevent shell metacharacter injection
CONFIG_ARGS=()
if [[ -n "$INPUT_CONFIG_PATH" ]]; then
  CONFIG_ARGS=("--config=${INPUT_CONFIG_PATH}")
fi

# Build EXTRA_ARGS as an array to prevent shell metacharacter injection
EXTRA_ARGS_ARRAY=()
if [[ -n "$INPUT_EXTRA_ARGS" ]]; then
  # Use read to split on whitespace safely into array elements
  IFS=' ' read -r -a EXTRA_ARGS_ARRAY <<< "$INPUT_EXTRA_ARGS"
fi

if [[ "$INPUT_ALL_FILES" == "true" ]]; then
  echo "Running ESLint on all files..."
  if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
    echo "Skipping annotations..."
    npx eslint "${CONFIG_ARGS[@]}" "${EXTRA_ARGS_ARRAY[@]}" && exit_status=$? || exit_status=$?
  else
    npx eslint "${CONFIG_ARGS[@]}" "${EXTRA_ARGS_ARRAY[@]}" -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
  fi
  
  if [[ "$INPUT_SKIP_ANNOTATIONS" != "true" ]]; then
    reviewdog -f=rdjson \
      -name=eslint \
      -reporter="${INPUT_REPORTER}" \
      -filter-mode="nofilter" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" < "$RD_JSON_FILE" || true
  fi

  if [[ $exit_status -ne 0 ]]; then
    echo "::error::Error running eslint."
    rm -rf "$TEMP_DIR"
    echo "::endgroup::"
    exit 1;
  fi
else
  if [[ -n "${INPUT_CHANGED_FILES[*]}" ]]; then
      echo "Running ESLint on changed files..."
      # Split changed files into an array to prevent shell metacharacter injection
      CHANGED_FILES_ARRAY=()
      IFS=' ' read -r -a CHANGED_FILES_ARRAY <<< "$INPUT_CHANGED_FILES"
      if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
        echo "Skipping annotations..."
        npx eslint "${CONFIG_ARGS[@]}" "${EXTRA_ARGS_ARRAY[@]}" "${CHANGED_FILES_ARRAY[@]}" && exit_status=$? || exit_status=$?
      else
        npx eslint "${CONFIG_ARGS[@]}" "${EXTRA_ARGS_ARRAY[@]}" -f="${ESLINT_FORMATTER}" "${CHANGED_FILES_ARRAY[@]}" > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
      fi
      
      if [[ "$INPUT_SKIP_ANNOTATIONS" != "true" ]]; then
        reviewdog -f=rdjson \
          -name=eslint \
          -reporter="${INPUT_REPORTER}" \
          -filter-mode="nofilter" \
          -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
          -level="${INPUT_LEVEL}" < "$RD_JSON_FILE" || true
      fi

      if [[ $exit_status -ne 0 ]]; then
        echo "::error::Error running eslint."
        rm -rf "$TEMP_DIR"
        echo "::endgroup::"
        exit 1;
      fi
  else
      echo "Skipping: No files to lint"
  fi
fi

rm -rf "$TEMP_DIR"

echo "::endgroup::"
