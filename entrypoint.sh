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

CONFIG_ARG=""

if [[ -n "$INPUT_CONFIG_PATH" ]]; then
  CONFIG_ARG="--config=${INPUT_CONFIG_PATH}"
fi

# extra_args is a whitespace-separated list; split (and glob) it exactly like
# upstream's unquoted ${EXTRA_ARGS} did. Nothing in the value is evaluated.
# shellcheck disable=SC2206
extra_args=($INPUT_EXTRA_ARGS)

if [[ "$INPUT_ALL_FILES" == "true" ]]; then
  echo "Running ESLint on all files..."
  if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
    echo "Skipping annotations..."
    npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} ${extra_args[@]+"${extra_args[@]}"} && exit_status=$? || exit_status=$?
  else
    npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} ${extra_args[@]+"${extra_args[@]}"} -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
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
  if [[ -n "${INPUT_CHANGED_FILES}" ]]; then
      echo "Running ESLint on changed files..."
      # Space-separated list of paths; split exactly like upstream's unquoted
      # ${INPUT_CHANGED_FILES}. Nothing in the value is evaluated.
      # shellcheck disable=SC2206
      changed_files=($INPUT_CHANGED_FILES)
      if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
        echo "Skipping annotations..."
        npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} ${extra_args[@]+"${extra_args[@]}"} ${changed_files[@]+"${changed_files[@]}"} && exit_status=$? || exit_status=$?
      else
        npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} ${extra_args[@]+"${extra_args[@]}"} -f="${ESLINT_FORMATTER}" ${changed_files[@]+"${changed_files[@]}"} > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
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
