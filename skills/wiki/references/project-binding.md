# Project Binding

Use this reference whenever the current project may be managing or reading a wiki
that lives outside the current working directory.

## Binding Fields

Projects bind to a wiki using these fields in their local `AGENTS.md` or
`CLAUDE.md`:

```markdown
## Wiki Binding
WikiMode: managed
WikiPath: <ABSOLUTE_PATH_TO_WIKI>
```

- `WikiMode: managed` means the project may update the bound wiki
- `WikiMode: reference` means the project may only read from the bound wiki
- `WikiPath` is the absolute path to the target wiki vault
- Example (Windows): `C:\Wiki_A`
- Example (macOS/Linux): `/Users/name/Wiki_A`

## Resolver Order

Before any wiki operation:

1. Check the current project's `AGENTS.md` for `WikiMode` and `WikiPath`
2. If missing, check the current project's `CLAUDE.md`
3. If still missing and the current directory already contains both `wiki/` and `.raw/`, use local vault mode
4. If none of the above match, no wiki is configured

When a bound wiki is configured:

- Read `{WikiPath}\CLAUDE.md` first to load the wiki's canonical rules
- Treat every `wiki/...` and `.raw/...` path in the skills as relative to `{WikiPath}`
- Never create or update `wiki/` or `.raw/` in the current project directory

## Mode Rules

### Managed

- Reads and writes are allowed
- Update the target wiki's `wiki/index.md`, `wiki/log.md`,
  `wiki/meta/context-state.json`, and `wiki/hot.md`
- Save new source material only inside `{WikiPath}\.raw\...`

### Reference

- Read-only access only
- You may read `wiki/hot.md`, `wiki/meta/context-state.json`, `wiki/index.md`,
  and relevant pages
- Do not create notes, write reports, save source files, update hot cache, or append to the log
- If a workflow normally writes, explain that the bound wiki is read-only

## Finalize and Git Boundaries

When a write happens in managed mode:

1. Update the target wiki's `wiki/index.md`, `wiki/log.md`,
   `wiki/meta/context-state.json`, and `wiki/hot.md` as required by the
   workflow
2. Keep all writes inside `{WikiPath}`
3. Never stage or commit wiki output in the current project's git repository
4. Do not auto-commit the bound wiki repository by default

Local vault mode may still use local convenience hooks, but bound-project mode
must not depend on hooks for correctness.
