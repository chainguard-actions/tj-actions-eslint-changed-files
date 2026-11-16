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

# EXTRA_ARGS is a whitespace-separated argument list. Upstream expanded it
# unquoted; assign it unquoted to an array so it splits (and globs) exactly as
# upstream did, without evaluating any shell syntax in the value.
# shellcheck disable=SC2206
extra_args_array=($EXTRA_ARGS)

if [[ "$INPUT_ALL_FILES" == "true" ]]; then
  echo "Running ESLint on all files..."
  if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
    echo "Skipping annotations..."
    npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} ${extra_args_array[@]+"${extra_args_array[@]}"} && exit_status=$? || exit_status=$?
  else
    npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} ${extra_args_array[@]+"${extra_args_array[@]}"} -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
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

      # Space-separated file list; split exactly as upstream's unquoted expansion.
      # shellcheck disable=SC2206
      changed_files_array=($INPUT_CHANGED_FILES)

      if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
        echo "Skipping annotations..."
        npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} ${extra_args_array[@]+"${extra_args_array[@]}"} ${changed_files_array[@]+"${changed_files_array[@]}"} && exit_status=$? || exit_status=$?
      else
        npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} ${extra_args_array[@]+"${extra_args_array[@]}"} -f="${ESLINT_FORMATTER}" ${changed_files_array[@]+"${changed_files_array[@]}"} > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
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
