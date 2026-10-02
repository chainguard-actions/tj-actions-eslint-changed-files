<!-- markdownlint-disable -->

# Hardening Report: tj-actions--eslint-changed-files/v25.3.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--eslint-changed-files/v25.3.2** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): Unquoted shell variable expansions of untrusted/workflow-controllable data in entrypoint.sh. The variables ${CONFIG_ARG} (sourced from inputs.config_path), ${EXTRA_ARGS} (sourced from inputs.extra_args), and ${INPUT_CHANGED_FILES} (sourced from steps.changed-files.outputs.all_changed_files) are all expanded without double-quotes in npx eslint invocations. This allows shell metacharacters embedded in those values to be interpreted by bash, enabling command injection. The shellcheck disable comments (SC2086) acknowledge the unquoted expansion but do not mitigate the security risk. Offending lines:
  Line 38: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} && exit_status=$? || exit_status=$?`
  Line 41: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE"`
  Line 57: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} ${INPUT_CHANGED_FILES} && exit_status=$? || exit_status=$?`
  Line 60: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} -f="${ESLINT_FORMATTER}" ${INPUT_CHANGED_FILES} > "$RD_JSON_FILE"`

Locations:

- `entrypoint.sh:38`
- `entrypoint.sh:41`
- `entrypoint.sh:57`
- `entrypoint.sh:60`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all four unquoted shell variable expansion vulnerabilities in entrypoint.sh:

1. CONFIG_ARG (single optional flag value): Changed from unquoted `${CONFIG_ARG}` to `${CONFIG_ARG:+"$CONFIG_ARG"}` — drops the argument entirely when empty, properly double-quoted when set.

2. EXTRA_ARGS (args-style list input from inputs.extra_args): Tokenized into a bash array `extra_args_array` using the xargs/printf/NUL-delimited read loop pattern for quote-aware splitting. Expanded as `"${extra_args_array[@]}"` in all npx eslint invocations.

3. INPUT_CHANGED_FILES (space-separated file list from steps.changed-files.outputs.all_changed_files): Tokenized into a bash array `changed_files_array` using the same xargs/printf/NUL-delimited read loop pattern. Expanded as `"${changed_files_array[@]}"` in all npx eslint invocations.

Removed the SC2086 shellcheck disable comments since they're no longer needed. The script uses bash (#!/usr/bin/env bash) so array syntax is valid.

