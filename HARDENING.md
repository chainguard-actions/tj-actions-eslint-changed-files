<!-- markdownlint-disable -->

# Hardening Report: tj-actions--eslint-changed-files/v25.3.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **tj-actions--eslint-changed-files/v25.3.2** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): Unquoted shell variable expansions of workflow-controllable data in entrypoint.sh. The variables `${CONFIG_ARG}` (derived from `inputs.config_path` via `INPUT_CONFIG_PATH`), `${EXTRA_ARGS}` (derived from `inputs.extra_args` via `INPUT_EXTRA_ARGS`), and `${INPUT_CHANGED_FILES}` (derived from `steps.changed-files.outputs.all_changed_files`) are all used unquoted in `npx eslint` commands. Unquoted expansion allows the shell to parse metacharacters (`;`, `|`, `&`, `$(...)`, etc.) out of these values, enabling command injection. The `# shellcheck disable=SC2086` comments acknowledge the word-splitting but do not mitigate the security risk. Offending lines: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} && exit_status=$? || exit_status=$?`, `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE"`, `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} ${INPUT_CHANGED_FILES} && exit_status=$? || exit_status=$?`, `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} -f="${ESLINT_FORMATTER}" ${INPUT_CHANGED_FILES} > "$RD_JSON_FILE"`

Locations:

- `entrypoint.sh:36`
- `entrypoint.sh:39`
- `entrypoint.sh:57`
- `entrypoint.sh:60`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all four script injection vulnerabilities in entrypoint.sh (lines 36, 39, 57, 60) by replacing unquoted variable expansions with properly quoted bash array expansions:
1. CONFIG_ARG (string) → CONFIG_ARGS (array): populated with '--config=...' when INPUT_CONFIG_PATH is set.
2. EXTRA_ARGS (string) → EXTRA_ARGS_ARRAY (array): uses `IFS=' ' read -r -a` to safely split INPUT_EXTRA_ARGS into individual array elements.
3. INPUT_CHANGED_FILES (unquoted string) → CHANGED_FILES_ARRAY (array): uses `IFS=' ' read -r -a` to safely split the space-separated file list.
All four npx eslint invocations now use `"${CONFIG_ARGS[@]}"`, `"${EXTRA_ARGS_ARRAY[@]}"`, and `"${CHANGED_FILES_ARRAY[@]}"` with proper double-quoting, preventing shell metacharacter injection. The SC2086 shellcheck disable comments were removed as they are no longer needed.

