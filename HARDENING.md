<!-- markdownlint-disable -->

# Hardening Report: tj-actions--eslint-changed-files/v25.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--eslint-changed-files/v25.3.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The composite action uses `reviewdog/action-setup@v1`, which is pinned to a mutable tag (`v1`) rather than an immutable 40-character commit SHA. This means the referenced action can be silently changed by the upstream repository, enabling a supply-chain attack. It should be pinned to a full SHA, e.g. `reviewdog/action-setup@<40-char-sha> # v1`.

Locations:

- `action.yml:74`

### script-injection (severity: high)

Rule (b) violation: In entrypoint.sh, the variables `${CONFIG_ARG}`, `${EXTRA_ARGS}`, and `${INPUT_CHANGED_FILES}` are expanded **unquoted** in `npx eslint` invocations. These variables are derived from workflow-controllable inputs (`inputs.config_path`, `inputs.extra_args`, and `steps.changed-files.outputs.all_changed_files` respectively), set via the `env:` block in action.yml. Unquoted expansion allows the shell to parse metacharacters (`;`, `|`, `&`, `$(...)`, etc.) from the values, enabling command injection. All four `npx eslint` call sites are affected (lines 35, 38, 57, 60). Each variable should be double-quoted: `"${CONFIG_ARG}"`, `"${EXTRA_ARGS}"`, `"${INPUT_CHANGED_FILES}"`.

Locations:

- `entrypoint.sh:35`
- `entrypoint.sh:38`
- `entrypoint.sh:57`
- `entrypoint.sh:60`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection

**Notes:**

1. Pinned reviewdog/action-setup@v1 to full SHA d8a7baabd7f3e8544ee4dbde3ee41d0011c3a93f in action.yml. 2. Fixed script injection in entrypoint.sh: CONFIG_ARG now uses ${CONFIG_ARG:+"$CONFIG_ARG"} for safe optional single-value expansion; INPUT_EXTRA_ARGS and INPUT_CHANGED_FILES are each tokenized into bash arrays via xargs (quote-aware splitting) and expanded as "${array[@]}" at all four npx eslint call sites.

