---
name: wiki-backup
description: Back up the resolved Obsidian wiki repository with git. Use when the user asks to back up, commit, push, sync, or checkpoint the wiki, especially when the wiki lives at a separate `WikiPath` from the current project. Resolve the active wiki root first, operate on the wiki repo only, never on the bound project repo, and keep `push` as an explicit separate action.
---

# wiki-backup: Back Up the Resolved Wiki Repo

Back up the wiki repo that the current project resolves to. Do not back up the
current project repo unless it is itself the wiki vault.

---

## Project Binding

Before any git action:

1. Read `../wiki/references/project-binding.md`.
2. Read `../wiki/references/git-setup.md`.
3. Resolve the active wiki root.
4. If the project declares `WikiPath`, operate inside `{WikiPath}`.
5. If there is no binding but the current directory contains both `wiki/` and
   `.raw/`, operate in the current directory as local-vault mode.
6. If `WikiMode` is `reference`, stop. Backup writes to the wiki repo and is not
   allowed in read-only mode.
7. Never stage, commit, or push the current project repo when it points at a
   separate wiki repo.

---

## Trigger Mapping

Route the request by intent:

| User says | Action |
|---|---|
| "backup wiki", "commit wiki", "checkpoint wiki" | Commit the resolved wiki repo |
| "push wiki", "sync wiki", "upload wiki backup" | Push the resolved wiki repo |
| "is wiki backup working?", "check wiki git backup" | Inspect repo state only |

If the user just completed a write-heavy wiki task and asks for backup, treat
that as a request to commit. Do not treat ordinary wiki writes as implicit
permission to run git.

---

## Safety Rules

- Operate in the resolved wiki root only.
- Prefer `git add -A` inside the wiki repo. Let `.gitignore` define exclusions.
- Never initialize git, create a remote, commit, or push unless the user asked
  for backup behavior explicitly.
- Never push just because a commit succeeded. `push` requires an explicit user
  request.
- If the wiki root is not a git repo, explain that backup is not configured yet.
  Offer initialization steps only when the user asks.
- If there are no changes, say so and stop. Do not create empty commits.

---

## Inspect Workflow

Use this for status or diagnostic requests:

1. Run `git rev-parse --show-toplevel` in the resolved wiki root.
2. Run `git status --short --branch`.
3. Run `git remote -v`.
4. Report whether:
   - the resolved wiki root is a git repo
   - there are staged or unstaged changes
   - a remote is configured
   - the branch is ahead, behind, or diverged

If `git rev-parse --show-toplevel` fails, report that the wiki root is not yet a
git repo.

---

## Commit Workflow

Use this only when the user explicitly asks to back up or commit the wiki.

1. Resolve the wiki root.
2. Verify it is a git repo with `git rev-parse --show-toplevel`.
3. Run `git status --short --branch` first so the user can understand scope.
4. Stage changes with `git add -A`.
5. Check for staged differences with `git diff --cached --quiet`.
6. If there is nothing staged, report "No wiki changes to back up."
7. Otherwise commit with:

```bash
git commit -m "wiki: backup YYYY-MM-DD HH:MM"
```

Use the current local time in the commit message. If the user gave a commit
message, use that instead.

Report:
- repo path used
- whether a commit was created
- branch name

---

## Push Workflow

Use this only when the user explicitly asks to push or sync the wiki.

1. Complete the Commit Workflow first if there are uncommitted changes.
2. Check remotes with `git remote -v`.
3. If no push remote exists, stop and report that the wiki repo has no remote.
4. Push the current branch to its configured upstream.
5. If upstream is missing, report that push needs an explicit target.

Do not invent remote names or branch names. Read them from git.

---

## Output Rules

- Be explicit about which repo path was used.
- When the wiki is bound through `WikiPath`, say that the project repo was left
  untouched.
- If backup is unavailable, explain the missing condition in one line: no git
  repo, no remote, read-only binding, or no changes.
