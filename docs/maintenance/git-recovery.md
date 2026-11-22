# Git Recovery Guide: Restoring Neovim Configuration

## 1\. Purpose

This guide documents how to recover Neovim configuration files using Git when an accidental edit, replacement, deletion, or commit damages the configuration.

The recovery process prioritizes:

- Preserving existing configuration files.
- Recovering previous versions from Git history.
- Avoiding unnecessary changes to unrelated files.
- Keeping local and remote Git history consistent.
- Verifying recovered files before committing changes.

**Repository:** `https://github.com/hetfs/nvim-config`

**Local repository:**

``` powershell
C:\Users\Administrator\Desktop\nvim-config
```

## 2\. Understand the Git recovery options

Git provides several ways to recover files.

| Command | Purpose |
| --- | --- |
| `git restore` | Restore files from a previous commit. |
| `git log` | Inspect commit history. |
| `git reflog` | Find previous branch and HEAD positions. |
| `git branch` | Create or inspect recovery branches. |
| `git diff` | Compare current and previous configurations. |
| `git revert` | Create a new commit that reverses an earlier commit. |
| `git reset` | Move the current branch to an earlier commit. |

Choose the recovery method based on what happened. Do not use `git reset --hard` as your first recovery option.

## 3\. Step 1: Inspect the repository

Open PowerShell and navigate to the repository:

``` powershell
cd C:\Users\Administrator\Desktop\nvim-config
```

Check the current branch and working tree:

``` powershell
git branch
git status
```

Inspect recent commits:

``` powershell
git log -5 --oneline
```

This establishes the current repository state before making changes.

## 4\. Step 2: Create a safety backup

Before recovering files, create a backup branch.

``` powershell
git branch backup-before-recovery
```

Verify that it exists:

``` powershell
git branch
```

If you have uncommitted changes, preserve them first. For example, create a patch:

``` powershell
git diff > ..\nvim-config-before-recovery.patch
git diff --cached > ..\nvim-config-staged-before-recovery.patch
```

These commands preserve tracked unstaged and staged changes separately. They do not include untracked files, so inspect those with:

``` powershell
git status --short
```

Copy important untracked files separately if necessary.

## 5\. Step 3: Find the previous working configuration

Inspect the commit history:

``` powershell
git log --oneline --all -- lua/config/options.lua
```

Replace `lua/config/options.lua` with the path of the file you want to recover.

To inspect a particular version:

``` powershell
git show COMMIT_ID:lua/config/options.lua
```

For example:

``` powershell
git show 68cc00a:lua/config/options.lua
```

This displays the file as it existed in that commit without changing your working tree.

If the commit is difficult to find, inspect the reference history:

``` powershell
git reflog --all
```

The reflog records recent movements of Git references, including previous HEAD positions and resets. It can help locate commits that are no longer reachable from your current branch.

## 6\. Step 4: Recover an individual configuration file

When only one file is damaged, restore that file instead of rolling back the entire repository.

Use:

``` powershell
git restore --source=COMMIT_ID -- lua/config/options.lua
```

Example:

``` powershell
git restore --source=68cc00a -- lua/config/options.lua
```

This restores the file from commit `68cc00a` into your working tree.

It does not automatically create a commit.

Inspect the result:

``` powershell
git diff -- lua/config/options.lua
git status
```

Repeat the process for other files if necessary.

**Important:** `git restore` can overwrite the current version of the selected file. Make sure you have preserved any changes you still need.

## 7\. Step 5: Recover multiple files

To restore several files from the same commit:

``` powershell
git restore --source=COMMIT_ID -- `
  lua/config/options.lua `
  lua/config/keymaps.lua `
  lua/config/autocmds.lua
```

Replace the paths with the actual files you need.

To restore a directory, use:

``` powershell
git restore --source=COMMIT_ID -- lua/config/
```

Be careful: this replaces the tracked files in that directory with their versions from the selected commit. It may overwrite newer changes in those files.

Always inspect the resulting diff before proceeding.

## 8\. Step 6: Compare recovered files with the previous version

Before committing, inspect the changes:

``` powershell
git diff
```

For a specific file:

``` powershell
git diff -- lua/config/options.lua
```

Check for whitespace errors:

``` powershell
git diff --check
```

Verify that unrelated configuration sections remain intact.

For example, when modifying `lua/config/options.lua`, check that all existing sections remain present:

- Shell
- Editor Behavior
- Indentation
- Search
- Window Management and Scrolling
- Display and Interface
- Clipboard
- Grep
- Folding
- Responsiveness and Input Timing
- Completion
- Diagnostics
- Files and Undo

Do not replace an entire configuration file when only one section needs modification.

## 9\. Step 7: Validate the recovered configuration

For Neovim Lua configuration files, run the project's syntax checks where available.

For example:

``` powershell
nvim --headless -u NONE `
  -c "lua assert(loadfile('lua/config/options.lua'))" `
  -c "qa"
```

This checks whether the selected Lua file can be parsed.

Then launch Neovim using your actual configuration:

``` powershell
nvim
```

Check for startup errors and confirm that the restored behavior works as expected.

Run the repository's relevant tests or smoke checks if they are available.

## 10\. Step 8: Commit the recovered configuration

Once the recovered files have passed inspection and validation, stage only the files you intended to recover:

``` powershell
git add lua/config/options.lua
```

Review the staged changes:

``` powershell
git diff --cached
git diff --cached --check
```

Commit:

``` powershell
git commit -m "restore previous Neovim configuration"
```

This creates a new commit without rewriting existing Git history.

## 11\. Step 9: Push the recovery to GitHub

Push the changes:

``` powershell
git push origin main
```

Verify synchronization:

``` powershell
git status
git log -3 --oneline
```

Expected status:

``` text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

Your local configuration and GitHub repository should now contain the recovered files.

## 12\. Recovering after an accidental commit

If you accidentally commit a broken configuration, first inspect the commit:

``` powershell
git log -5 --oneline
git show --stat COMMIT_ID
```

There are two different recovery approaches.

### Option A: Use `git revert` (recommended for published commits)

If the bad commit has already been pushed and you want to preserve shared history:

``` powershell
git revert COMMIT_ID
git push origin main
```

Git creates a new commit that reverses the selected commit.

This is generally the safest approach for shared branches.

### Option B: Use `git reset` (only when intentionally rewriting history)

If you explicitly want to move the branch back to an earlier commit:

First create a backup branch:

``` powershell
git branch backup-before-reset
```

Inspect the commits:

``` powershell
git log -5 --oneline
```

Move the branch back one commit:

``` powershell
git reset --hard HEAD~1
```

Verify the result:

``` powershell
git status
git log -3 --oneline
```

If the commit had already been pushed, updating GitHub requires rewriting the remote branch:

``` powershell
git push --force-with-lease origin main
```

**Warning:** This changes published branch history. Coordinate with anyone else using the branch and use `--force-with-lease`, not plain `--force`.

Do not use this approach merely to undo a file change. Prefer restoring the affected file or using `git revert`.

## 13\. Recovering a deleted backup branch

If you accidentally delete a recovery branch, the commits may still be recoverable.

Inspect the reflog:

``` powershell
git reflog --all
```

Find the commit that the deleted branch pointed to.

Recreate the branch:

``` powershell
git branch recovery-branch COMMIT_ID
```

For example:

``` powershell
git branch recovery-branch f46a4a5
```

If the commit still exists locally, this recreates a branch pointing to it.

If the commit is no longer available locally, check whether it exists on another remote or in another clone. Git cannot recover an object that has been permanently pruned and has no remaining copy.

## 14\. Step 10: Clean up temporary recovery branches

Keep your backup branch until the recovery is fully verified.

List branches:

``` powershell
git branch
```

When you are certain that the recovered configuration is correct and safely committed, remove the temporary branch:

``` powershell
git branch -d backup-before-recovery
```

If Git reports that the branch is not fully merged, inspect it before deciding whether to force-delete it.

Only when you are certain that you no longer need its commits:

``` powershell
git branch -D backup-before-recovery
```

The `-D` option deletes the branch reference even when Git considers it unmerged. It does not delete your current branch or working files.

## 15\. Real recovery example: `lua/config/options.lua`

This section records the actual recovery performed in this repository.

### Initial problem

A revised PowerShell shell configuration accidentally replaced the complete `lua/config/options.lua` file, removing existing Neovim option sections.

The incorrect change had already been committed and pushed.

### Recovery procedure

A backup branch was created:

``` powershell
git branch backup-before-reset
```

The previous commit was restored:

``` powershell
git reset --hard HEAD~1
```

The remote branch was synchronized with the restored history:

``` powershell
git push --force-with-lease
```

The original file was inspected:

``` powershell
git show HEAD:lua/config/options.lua
```

The incorrect version was compared with the original:

``` powershell
git show backup-before-reset:lua/config/options.lua
git diff HEAD backup-before-reset -- lua/config/options.lua
```

The original full configuration was preserved, and only the Windows PowerShell shell section was updated.

After validation, the corrected file was committed:

``` powershell
git add lua/config/options.lua

git commit -m "improve Windows PowerShell shell configuration"

git push
```

### Final verified state

The final commit was:

``` text
82fb4d9 improve Windows PowerShell shell configuration
```

The repository was synchronized with GitHub:

``` text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

The temporary branch was subsequently deleted:

``` powershell
git branch -D backup-before-reset
```

This completed the recovery.

## 16\. Recommended recovery workflow

For future configuration changes, follow this sequence:

1. Inspect the repository status.
2. Create a backup branch before risky changes.
3. Identify the correct previous commit.
4. Restore only the affected files.
5. Inspect the diff for unintended changes.
6. Run syntax checks and relevant tests.
7. Stage only the intended files.
8. Commit the recovered configuration.
9. Push to GitHub.
10. Verify that the working tree is clean.
11. Remove the temporary backup branch only after verification.

## 17\. Important rules

- Never replace a complete configuration file when only one section needs modification.
- Never run `git reset --hard` without understanding what will be discarded.
- Never force-push without first inspecting the branch history and creating a backup.
- Prefer `git restore` for individual file recovery.
- Prefer `git revert` for undoing published commits without rewriting history.
- Use `git reflog` when a previous commit or branch position is difficult to locate.
- Always inspect `git diff` before committing recovered files.
- Keep recovery commits focused and descriptive.

---

**Project principle:** Preserve the existing architecture. Recover only what is necessary. Validate before committing.

**Primary Git documentation:**

- Git Restore: https://git-scm.com/docs/git-restore
- Git Reflog: https://git-scm.com/docs/git-reflog
- Git Revert: https://git-scm.com/docs/git-revert
- Git Reset: https://git-scm.com/docs/git-reset
- Git Branch: https://git-scm.com/docs/git-branch
