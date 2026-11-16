<!-- markdownlint-disable -->

# Hardening Report: tj-actions--eslint-changed-files/v25.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--eslint-changed-files/v25.3.1** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

action.yml points a composite step at a mutable tag instead of a full 40-character commit SHA: `uses: reviewdog/action-setup@v1`. Whoever controls that tag can change the code this action runs. Pin it to a commit SHA and keep the tag as a comment (e.g. `@<sha> # v1`). The tj-actions/changed-files reference is already pinned to a SHA.

Locations:

- `action.yml:84`

### script-injection (severity: high)

Sub-rule (b): the 'Run eslint on changed files' composite step expands an environment variable without quotes in its run: block: `bash $GITHUB_ACTION_PATH/entrypoint.sh`. The check says to treat env vars in composite run blocks as untrusted when in doubt, and an unquoted path is also split on spaces and expanded as a glob. Quote it: `bash "$GITHUB_ACTION_PATH/entrypoint.sh"`.

Locations:

- `action.yml:103`

### script-injection (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. Rule (b) violation: In entrypoint.sh, the variables `${CONFIG_ARG}`, `${EXTRA_ARGS}`, and `${INPUT_CHANGED_FILES}` are expanded **unquoted** in `npx eslint` invocations. These variables are derived from workflow-controllable inputs (`inputs.config_path`, `inputs.extra_args`, and `steps.changed-files.outputs.all_changed_files` respectively), set via the `env:` block in action.yml. Unquoted expansion allows the shell to parse metacharacters (`;`, `|`, `&`, `$(...)`, etc.) from the values, enabling command injection. All four `npx eslint` call sites are affected (lines 35, 38, 57, 60). Each variable should be double-quoted: `"${CONFIG_ARG}"`, `"${EXTRA_ARGS}"`, `"${INPUT_CHANGED_FILES}"`.

Locations:

- `entrypoint.sh:35`
- `entrypoint.sh:38`
- `entrypoint.sh:57`
- `entrypoint.sh:60`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yml b/action.yml
index 0c6e0e9..ab9f058 100644
--- a/action.yml
+++ b/action.yml
@@ -3,7 +3,7 @@ description: Run ESLint on all changed files
 author: jackton1
 inputs:
   token:
-    description: "[GITHUB\_TOKEN](https://docs.github.com/en/free-pro-team@latest/actions/reference/authentication-in-a-workflow#using-the-github_token-in-a-workflow) or a repo scoped [Personal Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token)"
+    description: "[GITHUB TOKEN](https://docs.github.com/en/free-pro-team@latest/actions/reference/authentication-in-a-workflow#using-the-github_token-in-a-workflow) or a repo scoped [Personal Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token)"
     required: true
     default: ${{ github.token }}
   all_files:
@@ -53,9 +53,9 @@ inputs:
     required: false
     default: 'true'
   path:
-   description: "Relative path under GITHUB_WORKSPACE to the repository"
-   required: false
-   default: '.'
+    description: "Relative path under GITHUB_WORKSPACE to the repository"
+    required: false
+    default: '.'
   skip_initial_fetch:
     description: |
       Skip initially fetching additional history to improve performance for shallow repositories.
@@ -77,17 +77,33 @@ inputs:
       to silence ignore files warning [ignore file](https://eslint.org/docs/latest/use/configure/ignore-deprecated#using-an-alternate-file)
     required: false
     default: ''
-
 runs:
   using: 'composite'
   steps:
     - uses: reviewdog/action-setup@v1
       if: inputs.skip_annotations == 'false'
       with:
         reviewdog_version: v0.20.0
     - name: Get changed files
       id: changed-files
       uses: tj-actions/changed-files@2f7c5bfce28377bc069a65ba478de0a74aa0ca32 # v46
       if: inputs.all_files == 'false'
       with:
         path: ${{ inputs.path }}
@@ -124,7 +140,6 @@ runs:
         INPUT_FAIL_ON_ERROR: ${{ inputs.fail_on_error }}
         INPUT_REPORTER: ${{ inputs.reporter }}
         INPUT_SKIP_ANNOTATIONS: ${{ inputs.token && inputs.skip_annotations || 'true' }}
-
 branding:
   icon: check-square
   color: white

```

Locations:

- `action.yml`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed entrypoint.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/entrypoint.sh b/entrypoint.sh
index c491d02..19e02dc 100755
--- a/entrypoint.sh
+++ b/entrypoint.sh
@@ -26,22 +26,26 @@ if [[ "$INPUT_SKIP_ANNOTATIONS" != "true" ]]; then
   export REVIEWDOG_GITHUB_API_TOKEN=$INPUT_TOKEN
 fi
 
-EXTRA_ARGS="$INPUT_EXTRA_ARGS"
 CONFIG_ARG=""
 
 if [[ -n "$INPUT_CONFIG_PATH" ]]; then
   CONFIG_ARG="--config=${INPUT_CONFIG_PATH}"
 fi
 
+# Tokenize EXTRA_ARGS (a whitespace-separated list of flags) into an array
+extra_args=()
+if [[ -n "$INPUT_EXTRA_ARGS" ]]; then
+  while IFS= read -r -d '' t; do extra_args+=("$t"); done \
+    < <(printf '%s' "$INPUT_EXTRA_ARGS" | xargs printf '%s\0')
+fi
+
 if [[ "$INPUT_ALL_FILES" == "true" ]]; then
   echo "Running ESLint on all files..."
   if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
     echo "Skipping annotations..."
-    # shellcheck disable=SC2086
-    npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} && exit_status=$? || exit_status=$?
+    npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args[@]}" && exit_status=$? || exit_status=$?
   else
-    # shellcheck disable=SC2086
-    npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
+    npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args[@]}" -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
   fi
   
   if [[ "$INPUT_SKIP_ANNOTATIONS" != "true" ]]; then
@@ -60,15 +64,17 @@ if [[ "$INPUT_ALL_FILES" == "true" ]]; then
     exit 1;
   fi
 else
-  if [[ -n "${INPUT_CHANGED_FILES[*]}" ]]; then
+  if [[ -n "${INPUT_CHANGED_FILES}" ]]; then
       echo "Running ESLint on changed files..."
+      # Tokenize INPUT_CHANGED_FILES (space-separated list of paths) into an array
+      changed_files=()
+      while IFS= read -r -d '' t; do changed_files+=("$t"); done \
+        < <(printf '%s' "$INPUT_CHANGED_FILES" | xargs printf '%s\0')
       if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
         echo "Skipping annotations..."
-        # shellcheck disable=SC2086
-        npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} ${INPUT_CHANGED_FILES} && exit_status=$? || exit_status=$?
+        npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args[@]}" "${changed_files[@]}" && exit_status=$? || exit_status=$?
       else
-        # shellcheck disable=SC2086
-        npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} -f="${ESLINT_FORMATTER}" ${INPUT_CHANGED_FILES} > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
+        npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args[@]}" -f="${ESLINT_FORMATTER}" "${changed_files[@]}" > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
       fi
       
       if [[ "$INPUT_SKIP_ANNOTATIONS" != "true" ]]; then

```

Locations:

- `entrypoint.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, prior-fix

**Notes:**

Fixed all five findings.

action.yml:
- Pinned `reviewdog/action-setup` to commit d8a7baabd7f3e8544ee4dbde3ee41d0011c3a93f, keeping `# v1` as a comment.
- Put quotes around the script path: `bash "$GITHUB_ACTION_PATH/entrypoint.sh"`.
- Fixed the indentation of the `path` input. This is the prior-fix patch. I did not copy that patch's edit to the `token` description because it isn't a security change.

entrypoint.sh:
- `CONFIG_ARG` holds one value, so it is now passed as `${CONFIG_ARG:+"$CONFIG_ARG"}`. If it is empty, no argument is passed at all.
- `INPUT_EXTRA_ARGS` and `INPUT_CHANGED_FILES` are lists. Each one is now loaded into a bash array with an unquoted assignment (`extra_args=($INPUT_EXTRA_ARGS)`, `changed_files=($INPUT_CHANGED_FILES)`). That splits and expands patterns exactly the way upstream's unquoted `$VAR` did, and runs nothing in the value.
- The arrays are passed to eslint as `${arr[@]+"${arr[@]}"}`. This form avoids an unbound-variable error from `set -u` when an array is empty under bash 3.2, the version macOS ships.
- I fixed the `[*]` misuse in `${INPUT_CHANGED_FILES[*]}`, which was treating a plain string as an array.

I did not reuse the previous harden's `xargs` approach. `xargs` treats quotes and apostrophes in the value as special, which upstream's plain split did not, so arguments could come out differently.

I didn't run the action or any tests, so these changes haven't been checked at runtime.

Not changed: the script downloads its eslint formatter from reviewdog's `master` branch with no pinned version. That wasn't one of the findings.

