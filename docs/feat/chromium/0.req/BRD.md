# Chromium Profile Manager — BRD

<!-- links -->
[chromium-utils]: ../../../chromium_utils.sh "Existing chromium_utils.sh"
[ARCH]: ../../ARCH.md "bash_utils architecture doc"
[ckp]: ../../../../chrome-kw-port/ "chrome-kw-port: Chrome extension for keyword porting"
<!-- doc -->

## 1. Context

**Current state:** [`chromium_utils.sh`][chromium-utils] has 3 implemented functions (read-only keyword/ext query) + 3 commented-out stubs (keyword merge, extension merge, config merge). Chrome profiles are filesystem artifacts — structured directories of plaintext JSON + SQLite DBs — making them externally manageable without Chrome API.

**Goal:** Extend `chromium_utils.sh` into full profile manager: CRUD, copy/clone, selective section porting between profiles.

## 2. Chrome Profile Anatomy

A profile directory at `$CHROME_CONFIG/<ProfileName>/` contains these porting-relevant sections:

### 2.1 Plaintext JSON (jq-native)

| File | Type | Contents | Port Value |
|------|------|----------|------------|
| `Preferences` | JSON | Extensions settings, flags, UI prefs, password manager state, download dir, homepage, new-tab config, content settings, printer list, protocol handlers | **High** |
| `Bookmarks` | JSON | Bookmark tree (roots, folders, URLs, metadata) | **High** |
| `Secure Preferences` | JSON (MAC-protected) | Version-pinned prefs, extension install timestamps | **Low** (MAC-protected — write may break) |
| `../Local State` | JSON (profile-level) | Browser-wide: HTTP auth cache, profiles order, last-active profile, DNS cache | **Medium** |

### 2.2 SQLite DBs (sqlite3-native)

| File | Key Tables | Contents | Port Value |
|------|------------|----------|------------|
| `Web Data` | `keywords`, `autofill`, `credit_cards`, `token_service` | Search engines/shortcuts, form autofill, CC entries | **High** |
| `History` | `urls`, `visits`, `keyword_search_terms`, `downloads` | Browsing history, downloads log, search term history | **Medium** |
| `Cookies` | `cookies` | Cookie jar | **Medium** |
| `Favicons` | `favicons`, `favicon_bitmaps` | Cached favicon images + mappings | **Low** |
| `Login Data` | `logins` | Saved passwords | **High** (sensitive) |
| `Shortcuts` | `omni_box_shortcuts` | Omnibox shortcut index | **Low** |
| `Top Sites` | `top_sites` | Most-visited tiles | **Low** |

### 2.3 Filesystem Trees

| Directory | Contents | Port Value |
|-----------|----------|------------|
| `Extensions/` | Per-extension dirs (ID-named), each with `manifest.json`, `Extensions/`, `Local Extension Settings/`, `IndexedDB/` etc. | **High** |
| `Sessions/` | `Session_*`, `Tabs_*` — current/last session window+tab state (binary SNSS) | **Medium** |
| `Local Storage/` | LevelDB — per-origin `localStorage` data | **Low** |
| `IndexedDB/` | LevelDB — per-origin IndexedDB data | **Low** |
| `Service Worker/` | SW scripts + `CacheStorage/` | **Low** |

### 2.4 Profile Identity Files

| File | Purpose |
|------|---------|
| `../Local State` → `profile.info_cache` | Profile name, avatar, GAIA picture URL |
| `Google Profile Picture.png` | Cached avatar image |
| `First Run` | Sentinel — existence means profile initialized |

## 3. Functional Requirements

### FR-001: Profile CRUD

#### FR-001.1 — Create
Create new profile directory with valid structure. Seed `First Run`, minimal `Preferences` (browser defaults), empty `Bookmarks` bar.

```bash
chromium.profile.create [--browser chromium|google-chrome|brave|edge] [--name "Profile Name"] [--no-extensions]
```

#### FR-001.2 — List
Enumerate all profiles for a browser. Parse `Local State` → `profile.info_cache` for names, paths, last-active.

```bash
chromium.profile.ls [--browser chromium] [--json]
```

#### FR-001.3 — Delete
Remove profile directory. Optionally scrub from `Local State` → `profile.info_cache` to prevent "orphan" entries.

```bash
chromium.profile.rm [--browser chromium] [--scrub-registry] <profile_name|path>
```

#### FR-001.4 — Info
Print profile metadata: size (du), section file presence, creation date, last-used, extensions count, keyword count, bookmark count.

```bash
chromium.profile.info [--browser chromium] [--json] <profile_name|path>
```

### FR-002: Profile Copy/Clone

#### FR-002.1 — Full Clone
`cp -r` profile directory. Post-clone: strip unique identifiers (GAIA tokens, sync IDs), update `Preferences` → `profile.name`, add entry to `Local State` → `profile.info_cache`.

```bash
chromium.profile.clone [--browser chromium] [--name "New Name"] <src_profile> <dst_profile>
```

#### FR-002.2 — Sanitization on Clone
Remove or zero-out:
- `Web Data` → `token_service` table (OAuth tokens)
- `Preferences` → `account_info`, `gaia_info`, `google.services.*`
- `Cookies` — full clear
- `History` — optional clear (`--no-history` flag)
- `Login Data` — full clear (security: passwords must not be cloned silently)
- `Sessions/` — clear last-session state

Force-clear: `Login Data`, `Cookies`, `token_service`. Opt-in keep: `--keep-history`, `--keep-sessions`.

#### FR-002.3 — Dry-run
`--dry-run` flag prints what would happen (files copied, sanitized, DB rows dropped).

### FR-003: Section Porting

Port individual sections between profiles. Core pattern: `chromium.profile.port.<section>`.

#### FR-003.1 — Keywords (Search Engines)
**Status:** `chromium.search.keywords()` exists (read), `chromium.search.keywords.merge()` stubbed.

```bash
chromium.profile.port.keywords [--browser chromium] [--csv|--json] [--dry-run] <src_profile> <dst_profile>
```

Operation: export src → merge into dst (union, preserve Google/Bing defaults, deduplicate by `keyword`+`url`). Options: `--replace` (wipe dst first), `--skip-defaults` (don't auto-preserve Google/Bing).

#### FR-003.2 — Extensions (Settings + State)
**Status:** `chromium.ext.ls()` exists (read), `chromium.ext.merge()` stubbed.

```bash
chromium.profile.port.extensions [--browser chromium] [--settings-only|--full] [--dry-run] <src_profile> <dst_profile>
```

Two modes:
- `--settings-only`: Merge `Preferences` → `extensions.settings` keys (enable/disable state, update URL overrides). Does not copy extension files — target profile must have same extensions installed.
- `--full`: Copy `Extensions/` directory tree + merge settings. Extension must be closed (locked DBs).

#### FR-003.3 — Bookmarks

```bash
chromium.profile.port.bookmarks [--browser chromium] [--merge|--replace] [--dry-run] <src_profile> <dst_profile>
```

Default `--merge`: add src bookmarks under "Imported" folder, deduplicate URLs. `--replace`: overwrite dst Bookmarks file entirely.

#### FR-003.4 — Preferences (Selective)

```bash
chromium.profile.port.prefs [--browser chromium] [--keys "download.default_directory,extensions.settings"] [--dry-run] <src_profile> <dst_profile>
```

Deep-merge specific JSON paths. Use `jq` path expressions. Without `--keys`, interactive mode: list top-level pref groups, user selects.

#### FR-003.5 — History

```bash
chromium.profile.port.history [--browser chromium] [--days 30] [--dry-run] <src_profile> <dst_profile>
```

`ATTACH` dst DB, `INSERT OR IGNORE` from src urls+visits tables. Time-range filter via `--days`.

#### FR-003.6 — Cookies

```bash
chromium.profile.port.cookies [--browser chromium] [--domain "example.com"] [--dry-run] <src_profile> <dst_profile>
```

Domain-filtered ATTACH+INSERT. Default: all cookies. `--domain` can repeat.

#### FR-003.7 — Login Data (Passwords)

```bash
chromium.profile.port.logins [--browser chromium] [--dry-run] <src_profile> <dst_profile>
```

**Warning:** This copies encrypted password blobs. Only works between profiles on same machine (same OS keychain/lock key). Validation: check if src/dst have same `os_crypt` key before proceeding.

### FR-004: Section Import/Export (File-Based)

Detached from profile-to-profile port. Export to portable files for backup, sharing, version control. Import from same.

#### FR-004.1 — Keywords Export

```bash
chromium.keywords.export [--browser chromium] [--json|--csv|--sql] [--output FILE] <profile>
```

Formats:
- `--json`: array of `{short_name, keyword, url, suggest_url, terms[]}` objects. Same schema as [`chrome-kw-port`][ckp]
- `--csv`: flat table, header row, same columns
- `--sql`: `INSERT` statements, wrapped in transaction, with `DELETE` preamble (importable directly: `sqlite3 "Web Data" < file.sql`)

Without `--output`, write to stdout.

#### FR-004.2 — Keywords Import

```bash
chromium.keywords.import [--browser chromium] [--json|--csv|--sql] [--merge|--replace] [--dry-run] [--input FILE] <profile>
```

Auto-detect format if not specified (`--json`/`--csv`/`--sql`). `--merge` (default): upsert, preserve Google/Bing. `--replace`: wipe non-default keywords first. Without `--input`, read from stdin.

Validation: check `url` contains `{searchTerms}` or `%s`, reject malformed entries.

#### FR-004.3 — Extensions Export

```bash
chromium.extensions.export [--browser chromium] [--json|--tsv] [--full|--ids-only] [--output FILE] <profile>
```

- `--ids-only` (default): list `{id, name, enabled, version, install_time, update_url}` per extension
- `--full`: include `manifest` + `preferences` key for each extension (for full restore)
- `--json`: structured JSON array
- `--tsv`: tab-separated (for shell piping)

#### FR-004.4 — Extensions Import

```bash
chromium.extensions.import [--browser chromium] [--json|--tsv] [--install-missing] [--dry-run] [--input FILE] <profile>
```

- Only imports **settings** (enable/disable state, update URL overrides, toolbars). Does not install extensions — extensions must already exist in target profile
- `--install-missing`: if extension ID not found in target, print install URL to stderr for manual installation (can't install from CLI). Output a `urls-to-install.txt` sidecar
- `--full` (from export): merge full preferences state

#### FR-004.5 — Bookmark Files Export/Import

```bash
chromium.bookmarks.export [--browser chromium] [--output FILE] <profile>
chromium.bookmarks.import [--browser chromium] [--merge|--replace] [--input FILE] <profile>
```

Export: raw `Bookmarks` JSON (browser-native format → importable into any Chromium). Import: standard Bookmarks JSON format (also works with exported HTML bookmarks via conversion).

#### FR-004.6 — Format Auto-Detection

`_chromium.detect.format()` helper. Reads first 100 bytes of input file/stdin:
- Starts with `{` or `[` → JSON
- Starts with `-- ` or `BEGIN` → SQL
- Starts with header line, tab-separated → TSV
- Starts with header line, comma-separated → CSV

### FR-005: Bulk Porting

```bash
chromium.profile.port [--sections keywords,extensions,bookmarks,prefs,history,cookies] [--dry-run] <src_profile> <dst_profile>
```

Default `--sections all` runs keywords, extensions, bookmarks, history, cookies. Login Data excluded by default (must be explicit `--sections +logins` or `--include-logins`).

### FR-005: Bulk Porting

```bash
chromium.profile.port [--sections keywords,extensions,bookmarks,prefs,history,cookies] [--dry-run] <src_profile> <dst_profile>
```

Default `--sections all` runs keywords, extensions, bookmarks, history, cookies. Login Data excluded by default (must be explicit `--sections +logins` or `--include-logins`).

### FR-006: Profile Backup/Restore

#### FR-006.1 — Backup
Tar+gzip profile dir to `$XDG_DATA_HOME/chromium-utils/backups/<browser>/<profile>/<ISO-date>.tar.gz`. Exclude caches (GPUCache, DawnCache, Code Cache, GrShaderCache, ShaderCache, Cache, Service Worker/CacheStorage).

```bash
chromium.profile.backup [--browser chromium] [--include-caches] [--output DIR] <profile>
```

#### FR-006.2 — Restore
Extract backup, validate structure, overwrite target profile (must be closed).

```bash
chromium.profile.restore [--browser chromium] [--force] [--as "New Profile"] <backup_file> [<target_profile>]
```

### FR-007: Safety Guards

- **FR-007.1:** All SQLite writes require `--force` if Chrome running (`fuser` check on `SingletonLock` or DB files).
- **FR-007.2:** Auto-backup dst DB before any write (`Web Data.bak.timestamp`).
- **FR-007.3:** All port operations have `--dry-run`.
- **FR-007.4:** `chromium.profile.rm` requires explicit `--confirm` or interactive prompt.
- **FR-007.5:** Passwords port validates `os_crypt` compatibility — abort if mismatch.

### FR-008: Cross-Browser Profile Porting

Support mapping between Chromium variants: `chromium ↔ google-chrome ↔ brave ↔ edge ↔ vivaldi ↔ opera`.

```bash
chromium.profile.port [--from chromium] [--to google-chrome] [--sections keywords,bookmarks,extensions] <src> <dst>
```

Mapping table (profile root base paths + known differences in Preferences keys, extension IDs).

## 4. Non-Functional Requirements

### NFR-001: Code Style
Follow [`bash_utils` architecture][ARCH]: dot-namespace (`chromium.profile.*`), `while/case` opts, metadata arrays + `build_usage`, `export -f` + completions, `dep_check` for `sqlite3 jq fuser`.

### NFR-002: Dependencies
- `sqlite3` — all DB operations
- `jq` — JSON manipulation
- `fuser` — process detection (profile lock check)
- `tar`, `gzip` — backup
- No external network calls (offline-safe).

### NFR-003: File Organization
Implemented functions stay in `chromium_utils.sh`. Complex sections (bookmarks merging logic, preferences deep-merge) may extract to `bash_utils/src/chromium/` as sourced libraries.

### NFR-004: Idempotency
Port operations must be idempotent — running twice produces same result. Use `INSERT OR IGNORE` / deduplication by natural key.

### NFR-005: Error Recovery
- All SQL operations wrapped in transactions.
- Backup file created at `same_path.bak.<timestamp>` before any mutation.
- Failed port operations leave dst profile unchanged (transaction rollback).

## 5. Existing Functions (Baseline)

From [`chromium_utils.sh`][chromium-utils]:

| Function | Status | Action |
|----------|--------|--------|
| `chromium.search.keywords()` | **Live** | Keep, add to port pipeline |
| `chromium.search.engines()` | **Live** | Alias, keep |
| `chromium.ext.ls()` | **Live** | Keep, add to port pipeline |
| `chromium.search.keywords.merge()` | **Commented** | Uncomment, modernize, wire into `port.keywords` |
| `chromium.ext.merge()` | **Stub** | Implement |
| `chromium.ext.conf.merge()` | **Stub** | Implement |
| `chromium.cache.clearAll()` | **Commented** | Implement as `chromium.profile.cache.clear` |
| `chromium.keywords.export` | **New** | Export keywords to JSON/CSV/SQL file |
| `chromium.keywords.import` | **New** | Import keywords from JSON/CSV/SQL file |
| `chromium.extensions.export` | **New** | Export extension list/settings to JSON/TSV |
| `chromium.extensions.import` | **New** | Import extension settings from JSON/TSV |
| `chromium.bookmarks.export` | **New** | Export Bookmarks JSON |
| `chromium.bookmarks.import` | **New** | Import Bookmarks JSON |

## 6. Implementation Phases

### Phase 1 — Foundation
- `chromium.profile.ls` — parse Local State, list profiles
- `chromium.profile.info` — metadata dump
- `chromium.profile.create` — seed new profile
- Safety: `_chromium.profile.locked` (fuser check), `_chromium.db.backup` (sqlite3 backuper)

### Phase 2 — Export/Import + Read
- `chromium.keywords.export` (JSON/CSV/SQL) + `chromium.keywords.import`
- `chromium.extensions.export` (JSON/TSV) + `chromium.extensions.import`
- `chromium.bookmarks.export` + `chromium.bookmarks.import`
- Format auto-detection helper
- `chromium.profile.port.keywords` — profile-to-profile merge
- `chromium.profile.port.bookmarks` — profile-to-profile merge

### Phase 3 — Write/Mutate
- `chromium.profile.clone` — full copy + sanitize
- `chromium.profile.rm` — delete + scrub registry

### Phase 4 — Remaining Sections
- Extensions port (settings + files)
- History port (ATTACH+INSERT)
- Cookies port (domain-filtered)
- Preferences selective merge

### Phase 5 — Bulk + Cross-Browser
- `chromium.profile.port` (bulk dispatcher)
- `chromium.profile.backup` / `chromium.profile.restore`
- Cross-browser mapping + login security validation

## 7. Open Questions

1. **Q-001:** Is `Secure Preferences` write safe across versions? Likely no — limit to read-only, document risk.
2. **Q-002:** Extension porting: copy `Extensions/` files or force re-download? Files work if same Chrome version; stale extensions need reinstall.
3. **Q-003:** Profile-level `Local State` mutations safe? Editing `profile.info_cache` while Chrome runs may corrupt — require `--force`.
4. **Q-004:** Password porting cross-machine: encrypted blobs tied to OS keychain. Should we detect and warn, or just document?
5. **Q-005:** Bookmarks dedup: URL equality or title+URL composite key?

---

**Document Version:** 1.0  
**Status:** Draft — Requirements  
**Last Updated:** 2026-06-20