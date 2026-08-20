<!-- markdownlint-disable -->

# Hardening Report: tj-actions--eslint-changed-files/v25.3.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--eslint-changed-files/v25.3.2** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): In entrypoint.sh, several shell variables holding workflow-controllable input values are expanded **unquoted** inside `npx eslint` command invocations. Specifically:

1. `${CONFIG_ARG}` (derived from `inputs.config_path` → `INPUT_CONFIG_PATH`) is used unquoted: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} ...` (lines ~40 and ~55)
2. `${EXTRA_ARGS}` (derived from `inputs.extra_args` → `INPUT_EXTRA_ARGS`) is used unquoted in the same calls.
3. `${INPUT_CHANGED_FILES}` (derived from `steps.changed-files.outputs.all_changed_files`) is used unquoted: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} ${INPUT_CHANGED_FILES}` (lines ~57 and ~60).

Unquoted expansion allows an attacker-controlled value containing shell metacharacters (`;`, `|`, `&`, `$(...)`, whitespace, glob chars) to be interpreted by the shell, enabling command injection. The `# shellcheck disable=SC2086` comments in the script explicitly acknowledge these unquoted expansions. All three variables must be double-quoted (e.g., `"${EXTRA_ARGS}"`) or handled via an array to prevent injection.

Locations:

- `entrypoint.sh:40`
- `entrypoint.sh:43`
- `entrypoint.sh:57`
- `entrypoint.sh:60`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed script injection vulnerabilities in entrypoint.sh by replacing unquoted variable expansions with properly handled bash arrays:
1. CONFIG_ARG → config_args array (single optional flag, conditionally populated)
2. EXTRA_ARGS → extra_args array (tokenized via xargs/printf NUL-delimited pattern for quote-aware splitting, guarded with if [ -n ] check)
3. INPUT_CHANGED_FILES → changed_files array (same xargs/printf tokenization pattern, guarded with if [[ -n ]] check)
All npx eslint invocations now use "${array[@]}" expansion, preventing shell metacharacters in any of these values from being interpreted as shell commands. Removed all # shellcheck disable=SC2086 comments since unquoted expansions no longer exist.

### Iteration 2

**Fixes applied:** script-injection, missing-permissions

**Notes:**

Fixed three findings across two workflow files:
1. test.yml - Added `permissions: {}` at the top level to restrict GITHUB_TOKEN permissions.
2. test.yml - Fixed script injection in 'Commit outstanding changes' step: moved `${{ steps.verify-changed-files.outputs.changed_files }}` into an `env:` variable (`CHANGED_FILES`) and used xargs-based null-delimited tokenization to safely build the `git add` argument list, preventing shell injection via malicious filenames.
3. update-readme.yml - Added `permissions: contents: read` at the top level. The job uses PAT_TOKEN for PR creation, so GITHUB_TOKEN only needs read access for checkout operations.

