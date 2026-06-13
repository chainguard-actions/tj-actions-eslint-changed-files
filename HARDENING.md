<!-- markdownlint-disable -->

# Hardening Report: tj-actions--eslint-changed-files/v25.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **tj-actions--eslint-changed-files/v25.3.1** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The action uses `reviewdog/action-setup@v1` which is pinned to a mutable tag (`v1`) rather than a full 40-character commit SHA. This means the referenced action could be silently replaced with a different (potentially malicious) version without any change to this file. The other `uses:` reference (`tj-actions/changed-files@2f7c5bfce28377bc069a65ba478de0a74aa0ca32`) is correctly pinned to a SHA.

Locations:

- `action.yml:69`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses

**Notes:**

Replaced mutable tag `reviewdog/action-setup@v1` with the full commit SHA `reviewdog/action-setup@d8a7baabd7f3e8544ee4dbde3ee41d0011c3a93f # v1` in action.yml line 69. The SHA was resolved via lookup_action_sha. The other uses reference (tj-actions/changed-files) was already pinned to a full SHA and required no changes.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed shell metacharacter injection in entrypoint.sh by converting string variables to Bash arrays:
1. `CONFIG_ARG` changed from a string to an array (`CONFIG_ARG=()` / `CONFIG_ARG=("--config=${INPUT_CONFIG_PATH}")`)
2. `EXTRA_ARGS` changed from a string to an array populated via `read -ra EXTRA_ARGS <<< "$INPUT_EXTRA_ARGS"`
3. `INPUT_CHANGED_FILES` is now split into a `CHANGED_FILES` array via `read -ra CHANGED_FILES <<< "$INPUT_CHANGED_FILES"`, and the emptiness check was updated to use array length (`${#CHANGED_FILES[@]} -gt 0`) instead of the original `${INPUT_CHANGED_FILES[*]}` check
4. All four `npx eslint` invocations now use quoted array expansions `"${CONFIG_ARG[@]}"`, `"${EXTRA_ARGS[@]}"`, and `"${CHANGED_FILES[@]}"`
5. Removed the `# shellcheck disable=SC2086` comments that were suppressing the quoting warnings

