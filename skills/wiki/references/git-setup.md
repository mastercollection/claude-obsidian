# Git Setup

Initialize git in the wiki repo to get full history and protect against bad
writes.

Do this in the resolved wiki root itself, not in a separate project repo that
only points at the wiki via `WikiPath`.

---

## Initialize

```bash
cd "<vault-root>"
git init
git add -A
git commit -m "Initial vault scaffold"
```

---

## .gitignore

The root `.gitignore` in this repo already covers the right exclusions:

```
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.smart-connections/
.obsidian-git-data
.trash/
.DS_Store
```

`workspace.json` changes constantly as you move panes around. Excluding it keeps the diff clean.

---

## Obsidian Git Plugin (Optional)

After installing the plugin (see `plugins.md`):

Settings > Obsidian Git:
- Auto backup interval: **15 minutes**
- Auto backup after file change: on
- Push on backup: on (if you have a remote)
- Commit message: `vault: auto backup {{date}}`

This is optional. The default repo guidance is still manual commits for the wiki
repo. If you enable Obsidian Git, enable it only in the wiki repo itself.

---

## Remote (Optional)

To back up to GitHub:

```bash
git remote add origin https://github.com/yourname/your-vault
git push -u origin main
```

Keep the repo private if the vault contains personal notes.
