<!-- markdownlint-disable -->

# Hardening Report: tj-actions--eslint-changed-files/v25.3.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--eslint-changed-files/v25.3.2** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. Sub-rule (b): Unquoted shell variable expansions of untrusted/workflow-controllable data in entrypoint.sh. The variables ${CONFIG_ARG} (sourced from inputs.config_path), ${EXTRA_ARGS} (sourced from inputs.extra_args), and ${INPUT_CHANGED_FILES} (sourced from steps.changed-files.outputs.all_changed_files) are all expanded without double-quotes in npx eslint invocations. This allows shell metacharacters embedded in those values to be interpreted by bash, enabling command injection. The shellcheck disable comments (SC2086) acknowledge the unquoted expansion but do not mitigate the security risk. Offending lines:
  Line 38: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} && exit_status=$? || exit_status=$?`
  Line 41: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE"`
  Line 57: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} ${INPUT_CHANGED_FILES} && exit_status=$? || exit_status=$?`
  Line 60: `npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} -f="${ESLINT_FORMATTER}" ${INPUT_CHANGED_FILES} > "$RD_JSON_FILE"`

Locations:

- `entrypoint.sh:38`
- `entrypoint.sh:41`
- `entrypoint.sh:57`
- `entrypoint.sh:60`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yml b/action.yml
index b00dedf..bd02c49 100644
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
     - uses: reviewdog/action-setup@e04ffabe3898a0af8d0fb1af00c188831c4b5893 # v1.3.2
       if: inputs.skip_annotations == 'false'
       with:
         reviewdog_version: v0.20.0
     - name: Get changed files
       id: changed-files
       uses: tj-actions/changed-files@ed68ef82c095e0d48ec87eccea555d944a631a4c # v46.0.5
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
index c491d02..b720f65 100755
--- a/entrypoint.sh
+++ b/entrypoint.sh
@@ -33,15 +33,21 @@ if [[ -n "$INPUT_CONFIG_PATH" ]]; then
   CONFIG_ARG="--config=${INPUT_CONFIG_PATH}"
 fi
 
+# Tokenize EXTRA_ARGS (an args-style list) into an array using xargs for
+# quote-aware splitting, preventing shell metacharacter injection.
+extra_args_array=()
+if [ -n "$EXTRA_ARGS" ]; then
+  while IFS= read -r -d '' t; do extra_args_array+=("$t"); done \
+    < <(printf '%s' "$EXTRA_ARGS" | xargs printf '%s\0')
+fi
+
 if [[ "$INPUT_ALL_FILES" == "true" ]]; then
   echo "Running ESLint on all files..."
   if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
     echo "Skipping annotations..."
-    # shellcheck disable=SC2086
-    npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} && exit_status=$? || exit_status=$?
+    npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args_array[@]}" && exit_status=$? || exit_status=$?
   else
-    # shellcheck disable=SC2086
-    npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
+    npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args_array[@]}" -f="${ESLINT_FORMATTER}" . > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
   fi
   
   if [[ "$INPUT_SKIP_ANNOTATIONS" != "true" ]]; then
@@ -62,13 +68,20 @@ if [[ "$INPUT_ALL_FILES" == "true" ]]; then
 else
   if [[ -n "${INPUT_CHANGED_FILES[*]}" ]]; then
       echo "Running ESLint on changed files..."
+
+      # Tokenize INPUT_CHANGED_FILES (a space-separated list of file paths) into
+      # an array using xargs for quote-aware splitting.
+      changed_files_array=()
+      if [ -n "$INPUT_CHANGED_FILES" ]; then
+        while IFS= read -r -d '' t; do changed_files_array+=("$t"); done \
+          < <(printf '%s' "$INPUT_CHANGED_FILES" | xargs printf '%s\0')
+      fi
+
       if [[ "$INPUT_SKIP_ANNOTATIONS" == "true" ]]; then
         echo "Skipping annotations..."
-        # shellcheck disable=SC2086
-        npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} ${INPUT_CHANGED_FILES} && exit_status=$? || exit_status=$?
+        npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args_array[@]}" "${changed_files_array[@]}" && exit_status=$? || exit_status=$?
       else
-        # shellcheck disable=SC2086
-        npx eslint ${CONFIG_ARG} ${EXTRA_ARGS} -f="${ESLINT_FORMATTER}" ${INPUT_CHANGED_FILES} > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
+        npx eslint ${CONFIG_ARG:+"$CONFIG_ARG"} "${extra_args_array[@]}" -f="${ESLINT_FORMATTER}" "${changed_files_array[@]}" > "$RD_JSON_FILE" && exit_status=$? || exit_status=$?
       fi
       
       if [[ "$INPUT_SKIP_ANNOTATIONS" != "true" ]]; then

```

Locations:

- `entrypoint.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, prior-fix

**Notes:**

entrypoint.sh: every npx eslint call now passes CONFIG_ARG as ${CONFIG_ARG:+"$CONFIG_ARG"}, so it stays one quoted word and drops out when empty. EXTRA_ARGS and INPUT_CHANGED_FILES are now arrays (extra_args_array, changed_files_array), and each command expands them quoted, in a form that still works under set -u when an array is empty on bash 3.2. I did not reuse the previous harden's xargs split. Upstream expanded these variables unquoted, which splits on whitespace and globs but treats quotes literally; xargs would honour quotes and change the arguments. Assigning the array from an unquoted variable reproduces upstream's split and glob exactly, and nothing in the value is run as shell code. action.yml: re-applied the earlier patch (fixed the indentation of the path input and replaced the 'GITHUB\_TOKEN' escape with 'GITHUB TOKEN' in the description). I also put the entrypoint path in quotes: bash "$GITHUB_ACTION_PATH/entrypoint.sh".

