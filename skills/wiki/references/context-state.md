## Context State

`{WikiPath}/wiki/meta/context-state.json` is the machine-owned source of truth
for recent wiki context.

Use it to separate durable recent-state tracking from the human-readable log and
the generated hot cache.

### File Role

- `wiki/meta/context-state.json` = structured recent-state store for agents
- `wiki/hot.md` = generated cache for fast session startup
- `wiki/log.md` = append-only audit trail for humans

`hot.md` must be derived from `context-state.json`, not treated as the canonical
state store.

### Baseline Shape

```json
{
  "version": 1,
  "updated_at": "2026-04-19T09:00:00Z",
  "items": [
    {
      "id": "save:actionflow-plan-1-3-checklist",
      "source": "save",
      "title": "ActionFlow Plan 1-3 Checklist",
      "link": "[[ActionFlow Plan 1-3 Checklist]]",
      "summary": "Checklist for the ActionFlow plan phases 1 through 3.",
      "status": "active",
      "priority": 1,
      "session_key": "thread-abc123",
      "created_at": "2026-04-19T09:00:00Z",
      "updated_at": "2026-04-19T09:00:00Z",
      "expires_at": "2026-04-22T09:00:00Z",
      "tags": ["checklist", "plan"]
    }
  ]
}
```

### Rules

- Store only compact metadata and summaries. Never store full note bodies here.
- Use stable ids and upsert by logical note identity. Re-saving the same note
  updates the existing item instead of appending a duplicate.
- Prefer `status: active` for recently relevant work. Move stale items to
  `cooling` or `archived` instead of deleting them immediately.
- `expires_at` controls hot-cache eligibility, not hard deletion.
- If `context-state.json` cannot be updated, do not rewrite `hot.md`.

### Hot Cache Generation

Generate `wiki/hot.md` from `context-state.json` using these defaults unless the
current wiki overrides them:

- include only `active` items
- prefer items updated within the last 3 days
- sort by `priority` first, then `updated_at`
- merge duplicate mentions by `link`
- keep the final hot cache under roughly 500 words

### Workflow Order

For write workflows such as `save`, `ingest`, `autoresearch`, and any query flow
that saves a result:

1. write or update wiki note(s)
2. update `wiki/index.md`
3. append to `wiki/log.md`
4. upsert `wiki/meta/context-state.json`
5. regenerate `wiki/hot.md`
