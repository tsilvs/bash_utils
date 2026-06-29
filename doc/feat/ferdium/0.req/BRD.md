# SQL View Export/Import — Requirements

## Problem

Ferdium stores workspace→service membership as UUID JSON array in `workspaces.services`.

To batch-edit memberships, need to:

1. See human-readable workspace + service NAMES (not UUIDs)
2. Edit rows via diff/merge (add, remove, reorder)
3. Apply changes back — translating name→UUID behind scenes

Generic: any DB view that joins FK/JSON relations should be exportable as JSON,
editable, and re-importable with change detection.

## Data Model (from `server.sqlite`)

```
workspaces: id, workspaceId(UUID), name, order, services(JSON UUID[]), data(JSON), …
services:   id, serviceId(UUID), name, recipeId, settings(JSON), …
```

Relation: `workspaces.services` is `json_each(services).value` → `services.serviceId`.
No FK constraints. Names are user-assigned, mutable. UUIDs are stable.

## Core Requirements

### R1: Export includes stable row ID

Each exported row must carry a **stable identifier** — not display name.
For Ferdium: `serviceId` UUID (not service name).
Naming convention: `_id` column for the ID, others are display-friendly.
Matching during import uses `_id`, not names.

### R2: Diff-compatible output format

Output must be JSON Lines (.jsonl) — one JSON object per line.
Each line self-contained, sortable, `diff`-friendly.
Same rows always produce same JSON keys — deterministic ordering.

```
{"_id":"c324b8b3-...","workspace":"Prof","service":"Dis (Prof)"}
{"_id":"b1a190f4-...","workspace":"Prof","service":"Dis (Fam)"}
```

### R3: SQL file defines both directions

Single `.sql` file contains:

```
-- @db ~/.config/Ferdium/server.sqlite

-- EXPORT (required: include `_id` column)
SELECT s.serviceId AS _id, w.name AS workspace, s.name AS service
FROM workspaces w, json_each(w.services) je, services s
WHERE s.serviceId = je.value
ORDER BY w.name, s.name;

-- INSERT (template with :var placeholders)
INSERT INTO workspaces (services) VALUES (
  (SELECT json_insert(services, '$[#]', :_id) FROM workspaces WHERE name = :workspace)
)
ON CONFLICT …;

-- DELETE (template)
UPDATE workspaces SET services = (
  SELECT json_group_array(value) FROM json_each(services) WHERE value != :_id
) WHERE name = :workspace;
```

### R4: Change detection uses `_id` + sorted comparison

Import workflow:

1. Export current DB state → `current.jsonl`
2. User modifies → `edited.jsonl`
3. Diff `current.jsonl` ↔ `edited.jsonl` by `_id`
   - `_id` in edited but not current → INSERT
   - `_id` in current but not edited → DELETE
   - `_id` same, other fields differ → UPDATE
4. Apply generated SQL to DB

### R5: DB must be unlocked

Ferdium locks `server.sqlite` while running. Close app before import.

### R6: Dry-run default

Import shows diff summary + generated SQL. `--apply` flag required to write.
Shows: `+N` inserts, `-N` deletes, `~N` updates.

## Non-Requirements (out of scope)

- UI / TUI. CLI only.
- Multi-DB cross-references.
- Schema migrations.
- Concurrent access handling.
- UPDATE support for Ferdium case (workspace membership is binary: in or out).

## Target Users

Single user, local DB, offline-first. Replacement for clicking checkboxes in Ferdium sidebar settings.
