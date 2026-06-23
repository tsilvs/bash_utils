# TODO

## Tasks

### Opt metadata arrays + usage builder

#### Context

- `text_utils.sh` uses parallel arrays (`_PREFIX_OPTS_{SHORT,LONG,ARG,DESC}`) to drive both usage output and completions; `git_utils.sh` uses hardcoded heredocs — violates DRY, diverges from arch standard (see `docs/ARCH.md` §Phase 2)

#### Definition

- Add `_GIT_DIR_CHECK_OPTS_*` arrays; replace heredoc in `git.dir.check` with array loop
- [ ] Add `_GIT_URL_TO_DIR_OPTS_*` arrays; replace heredoc in `git.url.to_dir`
- [ ] Add `_GIT_CLONE_TO_DIR_OPTS_*` arrays; replace heredoc in `git.clone.to_dir`
- [ ] Add `_GIT_CLONE_LIST_OPTS_*` arrays; replace heredoc in `git.clone.list`
- [ ] Add `_GIT_REMOTE_SET_URL_OPTS_*` arrays; replace heredoc in `git.remote.set_url`

#### Acceptance / DoD

- [ ] No hardcoded heredoc usage blocks remain in `git_utils.sh`
- [ ] Usage output identical to current for each function

---

### `register_completion` migration

#### Context

- `register_simple_completion` is a flat list of flags; `register_completion "fn" "PREFIX"` (planned in `lib/cli.sh`) drives completions from metadata arrays — single source of truth

#### Definition

- [ ] Replace all `register_simple_completion` calls with `register_completion "fn" "PREFIX"` once `lib/cli.sh` exports it

#### Acceptance / DoD

- [ ] `register_simple_completion` absent from `git_utils.sh`
- [ ] Tab completion works for all five functions

---

### `dry_run_wrapper` + `run_cmd`

#### Context

- `git.clone.to_dir`, `git.clone.list`, `git.remote.set_url` use `local run="..."` + `eval "${run}"` — brittle, inconsistent with `run_cmd` pattern in `lib/bashlib.sh`

#### Definition

- [ ] Replace inline `local run` / `eval` in `git.clone.to_dir` with `run_cmd`
- [ ] Replace inline `local run` / `eval` in `git.clone.list` with `run_cmd`
- [ ] Replace inline `local run` / `eval` in `git.remote.set_url` with `run_cmd`
- [ ] Add `eval "$(dry_run_wrapper)"` at top of each affected function

#### Acceptance / DoD

- [ ] No bare `eval` of constructed strings remains
- [ ] Dry-run output unchanged

---

### `dep_check`

#### Context

- No dependency guards in `git_utils.sh`; `git` and `sed` assumed ambient but not validated

#### Definition

- [ ] Add `dep_check git` to `git.dir.check`, `git.clone.to_dir`, `git.clone.list`, `git.remote.set_url`
- [ ] Add `dep_check sed` to `git.url.to_dir`

#### Acceptance / DoD

- [ ] Missing `git`/`sed` prints error and returns 127

---

### `export -f`

#### Context

- Functions not exported — unavailable in subshells (inconsistent with other new-style files)

#### Definition

- [ ] Add `export -f git.dir.check git.url.to_dir git.clone.to_dir git.clone.list git.remote.set_url` at EOF

#### Acceptance / DoD

- [ ] `bash -c 'git.dir.check --help'` works after sourcing `git_utils.sh`

---

### `license.get`

#### Context

- Stub in source; needed for `git.init.proj` scaffolding

#### Definition

- [ ] Fetch license file by SPDX code from template source

#### Acceptance / DoD

- [ ] `license.get MIT` writes `LICENSE.md` with correct content

---

### `coc.get`

#### Context

- Stub in source; needed for `git.init.proj` scaffolding

#### Definition

- [ ] Fetch Code of Conduct by code from template source

#### Acceptance / DoD

- [ ] `coc.get contributor-covenant` writes `CODE_OF_CONDUCT.md`

---

### `readme.get`

#### Context

- Stub in source; needed for `git.init.proj` scaffolding

#### Definition

- [ ] Fetch README from template source

#### Acceptance / DoD

- [ ] `readme.get` writes `README.md` with project name pre-filled

---

### `fs.tree.spawn`

#### Context

- Stub in source; drives `git.init.proj` directory scaffolding

#### Definition

- [ ] Spawn directory tree from struct definition string

#### Acceptance / DoD

- [ ] Given struct string, correct dirs and empty files created
- [ ] Dry-run prints tree without writing

---

### `git.init.proj`

#### Context

- Stub in source; combines `fs.tree.spawn` + `license.get` + `coc.get` + `readme.get`

#### Definition

- [ ] Call `fs.tree.spawn` with project struct
- [ ] Call `license.get`, `coc.get`, `readme.get`
- [ ] Run `git init`

#### Acceptance / DoD

- [ ] Fresh dir initialised with full project scaffold and git repo

---

### `git.remote.repo.init`

#### Context

- Stub in source; needs multi-provider API support (GitHub, GitLab, Gitea)

#### Definition

- [ ] Token prompt via `read -s`
- [ ] Read repo metadata from `repo.json` (name, description, visibility)
- [ ] Abstract endpoint + headers per provider
- [ ] `curl` POST to create remote repo

#### Acceptance / DoD

- [ ] Repo created on target provider via API
- [ ] Token never echoed to terminal or logs

---

### `git.localhost.setup`

#### Context

- Stub in source; needed for LAN git server workflow

#### Definition

- [ ] Create non-graphical `git` Linux user
- [ ] Configure SSH access for that user

#### Acceptance / DoD

- [ ] `ssh git@localhost` drops into git-shell
- [ ] Normal shell login rejected

---

### `git.dirs.noremote`

#### Context

- Stub in source; useful for auditing repos missing a specific remote (e.g. LAN backup)

#### Definition

- [ ] Accept remote name as argument
- [ ] Walk `*/` subdirs, print those missing that remote in `.git/config`

#### Acceptance / DoD

- [ ] Prints only dirs where specified remote is absent
- [ ] Skips non-git dirs silently
