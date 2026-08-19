<!-- markdownlint-disable -->

# Hardening Report: tj-actions--eslint-changed-files/v25.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--eslint-changed-files/v25.3.1** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple uses: references are pinned to mutable tags or branch names instead of immutable 40-character commit SHAs, making the action vulnerable to supply-chain attacks.

action.yml: uses: reviewdog/action-setup@v1

.github/workflows/codacy-analysis.yml: codacy/codacy-analysis-cli-action@v4.4.5, github/codeql-action/upload-sarif@v3

.github/workflows/codeql.yml: github/codeql-action/init@v3, github/codeql-action/autobuild@v3, github/codeql-action/analyze@v3

.github/workflows/rebase.yml: cirrus-actions/rebase@1.8

.github/workflows/sync-release-version.yml: tj-actions/release-tagger@v4, tj-actions/sync-release-version@v13, tj-actions/git-cliff@v1, peter-evans/create-pull-request@v7

.github/workflows/test.yml: reviewdog/action-shellcheck@v1.30, actions/setup-node@v4 (x2), tj-actions/verify-changed-files@v20, ad-m/github-push-action@master

.github/workflows/update-readme.yml: tj-actions/auto-doc@v3, tj-actions/remark@v3, tj-actions/verify-changed-files@v20, peter-evans/create-pull-request@v7

Locations:

- `action.yml:63`
- `.github/workflows/codacy-analysis.yml:35`
- `.github/workflows/codacy-analysis.yml:55`
- `.github/workflows/codeql.yml:40`
- `.github/workflows/codeql.yml:55`
- `.github/workflows/codeql.yml:65`
- `.github/workflows/rebase.yml:15`
- `.github/workflows/sync-release-version.yml:14`
- `.github/workflows/sync-release-version.yml:16`
- `.github/workflows/sync-release-version.yml:21`
- `.github/workflows/sync-release-version.yml:23`
- `.github/workflows/test.yml:17`
- `.github/workflows/test.yml:27`
- `.github/workflows/test.yml:70`
- `.github/workflows/test.yml:88`
- `.github/workflows/test.yml:110`
- `.github/workflows/update-readme.yml:11`
- `.github/workflows/update-readme.yml:16`
- `.github/workflows/update-readme.yml:19`
- `.github/workflows/update-readme.yml:33`

### missing-permissions (severity: medium)

Three workflow files have no top-level permissions: key and no job-level permissions: keys on any of their jobs. Without explicit permissions, the GITHUB_TOKEN is granted its default (potentially broad) permissions, violating least-privilege: test.yml, rebase.yml, update-readme.yml.

Locations:

- `.github/workflows/test.yml:1`
- `.github/workflows/rebase.yml:1`
- `.github/workflows/update-readme.yml:1`

### script-injection (severity: high)

Sub-rule (a) violation: A ${{ }} expression is interpolated directly inside a run: shell command string. In the 'Commit outstanding changes' step, the value of steps.verify-changed-files.outputs.changed_files (a steps.*.outputs.* context, which is workflow-controllable) is passed directly to git add without quoting or sanitization: `git add ${{ steps.verify-changed-files.outputs.changed_files }}`. An attacker who can influence the changed file list (e.g. via a crafted filename) could inject arbitrary shell commands into the runner.

Locations:

- `.github/workflows/test.yml:83`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, missing-permissions, script-injection

**Notes:**

Fixed all three findings:

1. unpinned-uses: Pinned all mutable tag/branch references to full 40-character commit SHAs across action.yml, codacy-analysis.yml, codeql.yml, rebase.yml, sync-release-version.yml, test.yml, and update-readme.yml. All original tags preserved as inline comments.

2. missing-permissions: Added top-level permissions blocks to test.yml (contents: write, pull-requests: read), rebase.yml (contents: write, pull-requests: read), and update-readme.yml (contents: write, pull-requests: write).

3. script-injection: In test.yml 'Commit outstanding changes' step, moved `${{ steps.verify-changed-files.outputs.changed_files }}` out of the run: shell string into an env: block as CHANGED_FILES, then referenced it as "$CHANGED_FILES" in the shell script to prevent shell command injection.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed all four script injection vulnerabilities in entrypoint.sh by converting CONFIG_ARG, EXTRA_ARGS, and INPUT_CHANGED_FILES from unquoted string variables to bash arrays:

1. CONFIG_ARG: Now a bash array (CONFIG_ARG=()), populated with ("--config=${INPUT_CONFIG_PATH}") when set. Expanded as "${CONFIG_ARG[@]}".

2. EXTRA_ARGS: Now a bash array (EXTRA_ARGS=()), populated via `read -ra EXTRA_ARGS <<< "$INPUT_EXTRA_ARGS"` which splits on whitespace only, not on shell metacharacters. Expanded as "${EXTRA_ARGS[@]}".

3. INPUT_CHANGED_FILES: Now split into a CHANGED_FILES bash array via `read -ra CHANGED_FILES <<< "$INPUT_CHANGED_FILES"`. The emptiness check was updated to use array length `${#CHANGED_FILES[@]} -gt 0`. Expanded as "${CHANGED_FILES[@]}".

All four npx eslint invocations now use safe array expansions, preventing shell metacharacters in attacker-controlled inputs from being interpreted as shell commands. The SC2086 shellcheck disable comments were removed as they are no longer needed.

