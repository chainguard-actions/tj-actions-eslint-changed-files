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

EXTRA_ARGS="$INPUT_EXTRA_ARGS"
CONFIG_ARG=""

if [[ -n "$INPUT_CONFIG_PATH" ]]; then
  CONFIG_ARG="--config=${INPUT_CONFIG_PATH}"
fi

# Tokenize EXTRA_ARGS (an args-style list) into an array using xargs for
# quote-aware splitting, preventing shell metacharacter injection.
extra_args_array=()
if [ -n "$EXTRA_ARGS" ]; then
  while IFS= read -r -d '' t; do extra_args_array+=("$t"); done \
    < <(printf '%s' "$EXTRA_ARGS" | xargs printf '%s\0')
fi

if [[ "$INPUT_ALL_FILES" == "true" ]]; then
  echo "Running ESLint on all files..."
  if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
    echo "Skipping annotations..."
    npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args_array[@]}" && exit_status=$? || exit_status=$?
  else
    npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args_array[@]}" -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
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

      # Tokenize INPUT_CHANGED_FILES (a space-separated list of file paths) into
      # an array using xargs for quote-aware splitting.
      changed_files_array=()
      if [ -n "$INPUT_CHANGED_FILES" ]; then
        while IFS= read -r -d '' t; do changed_files_array+=("$t"); done \
          < <(printf '%s' "$INPUT_CHANGED_FILES" | xargs printf '%s\0')
      fi

      if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
        echo "Skipping annotations..."
        npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args_array[@]}" "${changed_files_array[@]}" && exit_status=$? || exit_status=$?
      else
        npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args_array[@]}" -f="${ESLINT_FORMATTER}" "${changed_files_array[@]}" > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
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
