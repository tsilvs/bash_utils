# Architecture — Library Extraction & Code Style Migration

## 1. Current State

Two code styles coexist — NEW (8 files) and OLD (5 files + 3 skeletons):

| Style        | Files                                                                                                      | Key Traits                                                                                     |
| ------------ | ---------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **NEW**      | ffmpeg_utils, mktouch_utils, text_utils, pdf_utils, git_utils, csv_utils, diff_utils, adb_utils, pkg_utils | `while/case` parsing, opt metadata arrays, `FUNCNAME[0]`, dep arrays, `export -f`, completions |
| **MIXED**    | alias_functions, podman_utils                                                                              | Partial migration; some fns new-style, rest old                                                |
| **OLD**      | bash_utils, fs_utils, conf_utils, encode_decode_utils, docker_utils                                        | `[[ " $* " =~ ' --help ' ]]`, `echo -e`, no `export -f`, no deps check, no completions         |
| **SKELETON** | json_utils, systemd_utils, yt_utils                                                                        | Header-only, no real functions                                                                 |

Boilerplate repetition counts across NEW-style files:

- `run_cmd` inner fn: ~8 definitions
- `for d in deps` check: ~25 occurrences
- Opt metadata + usage builder: ~20 blocks
- Completion functions: 14 definitions
- `showhelp` guard: ~30 occurrences

Current shared lib (`lib/bashlib.sh`): skeleton with `have_cmd` only.

## 2. Target Library Architecture

```
lib/
├── bashlib.sh     # Core utilities: have_cmd, run_cmd, dep_check, helpers
├── cli.sh         # CLI framework: metadata arrays → usage builder, arg validation
└── completion.sh  # Completion generator: boilerplate _fn_complete template
```

### Layer 1 — `lib/bashlib.sh`

Purpose: stateless utility functions used across all scripts.

```bash
# ── Dependency check ──────────────────────────────────────────────────────────
# Usage: dep_check ffmpeg awk magick
# Returns 127 if any missing
dep_check() {
    local d
    for d in "$@"; do
        command -v "$d" &>/dev/null || {
            echo "Error: dependency missing: $d" >&2
            return 127 2>/dev/null || exit 127
        }
    done
}

# ── Dry-run wrapper ───────────────────────────────────────────────────────────
# Generates run_cmd() inside caller scope
# Usage: eval "$(dry_run_wrapper)"
dry_run_wrapper() {
    cat <<-'EOF'
    run_cmd() {
        if (( dryrun )); then
            echo "DRY-RUN: $*"
        else
            "$@"
        fi
    }
EOF
}

# ── File validation ───────────────────────────────────────────────────────────
# Usage: validate_input "$file" || return
validate_input() {
    [[ -f "$1" && -r "$1" ]] && return 0
    echo "Error: cannot access $1" >&2
    return 1
}

# ── Extension check ───────────────────────────────────────────────────────────
# Usage: ext_check "file.mkv" "${_EXTS[@]}" || return
ext_check() {
    local file="$1" ext; shift
    ext="${file##*.}"; ext="${ext,,}"
    for e in "$@"; do [[ "$ext" == "$e" ]] && return 0; done
    return 1
}

# ── Mktemp with cleanup ───────────────────────────────────────────────────────
# Usage: local tmpdir; tmpdir=$(make_temp "$(dirname "$file")" "prefix")
# trap cleanup_temp "$tmpdir" EXIT
make_temp() {
    mktemp -d -p "$1" "${2}_tmp.XXXXXX"
}
cleanup_temp() {
    [[ -n "$1" && -d "$1" ]] && rm -rf "$1"
}

export -f dep_check validate_input ext_check make_temp cleanup_temp
```

### Layer 2 — `lib/cli.sh`

Purpose: option metadata arrays → usage string, arg parsing, validation.

Current pattern (duplicated ~20x):

```bash
_DOMAIN_ACTION_OPTS_SHORT=(-s -o -n -h)
_DOMAIN_ACTION_OPTS_LONG=(--speed --output --dry-run --help)
_DOMAIN_ACTION_OPTS_ARG=("FACTOR" "FILE" "" "")
_DOMAIN_ACTION_OPTS_DESC=(...)
for ((i=0; i<${#_SHORT[@]}; i++)); do printf -v line '\t%-32s%s\n' ...; usage_opts+="$line"; done
```

Extraction:

```bash
# ── Build usage string from metadata arrays ──────────────────────────────────
# Convention: _<FN_SHORT>_OPTS_{SHORT,LONG,ARG,DESC}
# Usage: eval "$(build_usage "FFMPEG_VIDEO_SPEED" "$fn" "description")"
build_usage() {
    local prefix="$1" fn="$2" desc="$3" extra_help="$4"
    local var_short="${prefix}_OPTS_SHORT[@]"
    local var_long="${prefix}_OPTS_LONG[@]"
    local var_arg="${prefix}_OPTS_ARG[@]"
    local var_desc="${prefix}_OPTS_DESC[@]"
    local short_arr=("${!var_short}")
    local long_arr=("${!var_long}")
    local arg_arr=("${!var_arg}")
    local desc_arr=("${!var_desc}")
    local opts_block="" line sig i

    for ((i=0; i<${#short_arr[@]}; i++)); do
        sig="${short_arr[$i]}, ${long_arr[$i]}${arg_arr[$i]:+ ${arg_arr[$i]}}"
        printf -v line '\t%-32s%s\n' "$sig" "${desc_arr[$i]}"
        opts_block+="$line"
    done

    cat <<-EOF
    local usage="Usage: $fn [OPTIONS] $desc
    $extra_help
    Options:
    $opts_block"
EOF
}

# ── Parse options against metadata arrays ────────────────────────────────────
# Usage: parse_opts "FFMPEG_VIDEO_SPEED" "$@" && shift $?
# Sets local variables: dryrun, showhelp, and per-option targets
# Returns number of consumed args via _PARSED_SHIFT
parse_opts() {
    # Complex due to bash scoping — requires eval-based injection into caller
    # Better approach: inline helper that generates the case block
    :
}
```

Due to bash scoping limits, the option parsing is better served as a **generator** that outputs the `while/case` block to `eval` in caller scope, rather than a function call. But this adds complexity. A pragmatic middle ground: keep opt metadata + usage builder shared, keep per-function `while/case` inline (most readable).

### Layer 3 — `lib/completion.sh`

Purpose: single completion generator for all `_fn_complete` boilerplate.

Current pattern (14x duplicated):

```bash
_fn_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local all_opts=("${_PREFIX_OPTS_SHORT[@]}" "${_PREFIX_OPTS_LONG[@]}")
    case "$cur" in
    -*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
    *)  mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
    esac
}
complete -F _fn_complete fn
```

Extraction:

```bash
# ── Register bash completion for a function ──────────────────────────────────
# Usage: register_completion "fn" "FN_PREFIX"
# Generates _fn_complete() + complete -F _fn_complete fn
register_completion() {
    local fn="$1" prefix="$2"
    local fn_clean="${fn//./_}"
    eval "
    _${fn_clean}_complete() {
        local cur=\"\${COMP_WORDS[COMP_CWORD]}\"
        local all_opts=(\"\${${prefix}_OPTS_SHORT[@]}\" \"\${${prefix}_OPTS_LONG[@]}\")
        case \"\$cur\" in
        -*) mapfile -t COMPREPLY < <(compgen -W \"\${all_opts[*]}\" -- \"\$cur\") ;;
        *)  mapfile -t COMPREPLY < <(compgen -f -- \"\$cur\") ;;
        esac
    }
    complete -F _${fn_clean}_complete $fn
    "
}

export -f register_completion
```

## 3. Migration Plan

### Phase 1 — Build Libraries (this sprint)

| File                | Action | Details                                                                            |
| ------------------- | ------ | ---------------------------------------------------------------------------------- |
| `lib/bashlib.sh`    | Expand | Add dep_check, dry_run_wrapper, validate_input, ext_check, make_temp, cleanup_temp |
| `lib/cli.sh`        | Create | Add build_usage, register_completion; usage builder from metadata arrays           |
| `lib/completion.sh` | Create | Add register_completion helper (or merge into cli.sh)                              |

### Phase 2 — Wire Libraries Into NEW Files

All 9 NEW-style files get `source` line at top, function bodies refactored to use lib calls.

| File               | Estimated Δ        | Changes                                                                                                                    |
| ------------------ | ------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `ffmpeg_utils.sh`  | ~200 lines removed | replace `for d in deps` → dep_check, run_cmd → lib version, usage builder → build_usage, completions → register_completion |
| `mktouch_utils.sh` | ~30 lines removed  | dep_check, run_cmd, completion                                                                                             |
| `text_utils.sh`    | ~20 lines removed  | dep_check, run_cmd, completion                                                                                             |
| `pdf_utils.sh`     | ~30 lines removed  | dep_check, run_cmd, completion                                                                                             |
| `git_utils.sh`     | ~10 lines removed  | dep_check                                                                                                                  |
| `csv_utils.sh`     | ~10 lines removed  | dep_check, make_temp cleanup                                                                                               |
| `diff_utils.sh`    | ~5 lines removed   | dep_check                                                                                                                  |
| `adb_utils.sh`     | ~10 lines removed  | dep_check                                                                                                                  |
| `pkg_utils.sh`     | ~5 lines removed   | dep_check                                                                                                                  |

### Phase 3 — Migrate MIXED Files

| File                 | Action                        | Details                                                                        |
| -------------------- | ----------------------------- | ------------------------------------------------------------------------------ |
| `alias_functions.sh` | Refactor old fns to new style | Dot-namespace bare fns, add `export -f`, add completions for multi-opt fns     |
| `podman_utils.sh`    | Refactor old fns to new style | Replace `[[ " $* " =~ ' --help ' ]]` → `while/case`, heredoc help, `export -f` |

### Phase 4 — Rewrite OLD Files

| File                     | Action         | Details                                                                                           |
| ------------------------ | -------------- | ------------------------------------------------------------------------------------------------- |
| `bash_utils.sh`          | Full rewrite   | Dot-namespace (`bash.history.ls`, `bash.ls.git`, `bash.find.roots`), `while/case`, compat aliases |
| `fs_utils.sh`            | Rewrite per fn | `while/case`, `FUNCNAME[0]`, heredoc, dep_check, export -f                                        |
| `conf_utils.sh`          | Rewrite        | Add option parsing, validation                                                                    |
| `encode_decode_utils.sh` | Rewrite        | Namespace (`encode.img2base64`), option parsing                                                   |
| `docker_utils.sh`        | Rewrite        | Namespace (`docker.user.group.add` already OK), add `while/case` to multi-opt fns, `export -f`    |

### Phase 5 — Populate SKELETON Files

| File               | Action                                     |
| ------------------ | ------------------------------------------ |
| `json_utils.sh`    | Implement planned functions with new style |
| `systemd_utils.sh` | Implement planned functions with new style |
| `yt_utils.sh`      | Implement planned functions with new style |

## 4. Function Naming Convention (Standard)

```
<domain>.<action>[.<subaction>]()
```

- **domain**: single lowercase word (`ffmpeg`, `pdf`, `csv`, `git`, `adb`, `podman`, `docker`, `txt`, `fs`, `conf`, `encode`, `json`, `systemd`, `yt`)
- **action**: verb (`speed`, `merge`, `flat`, `compress`, `install`, `check`, `ls`, `rm`)
- **subaction**: optional qualifier (`watermark`, `tag`, `organize`)
- **private helpers**: `_<domain>.<action>()` (leading underscore)

Exception: `mktouch` and `bash_utils` are domains already established.

## 5. File Structure Invariant

```
lib/
├── bashlib.sh       # Shared utilities (dep_check, dry_run, validate_input, etc.)
├── cli.sh           # CLI framework (build_usage, register_completion)
*.sh                 # Domain utils (source lib/shared.sh at top)
data/                # Config data (presets, lint rules, etc.)
```

Each `*.sh` file:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

# Domain functions...
# export -f at EOF
```

## 6. Patch Strategy (Per File)

Each old-style fn needs surgical changes:

| Old Pattern                                                        | Replace With                                                       |
| ------------------------------------------------------------------ | ------------------------------------------------------------------ |
| `[[ " $* " =~ ' --help ' ]] && { echo -e "Usage:..."; return 0; }` | `while/case` + heredoc usage                                       |
| `basename "$0"`                                                    | `${FUNCNAME[0]}`                                                   |
| `return $?`                                                        | `return` (implicit)                                                |
| `plain_item=$(echo $item \| sed ...)`                              | `"$item"` quoted + `sed '...'`                                     |
| bare fn name                                                       | `domain.action()`                                                  |
| missing `export -f`                                                | `export -f domain.action1 domain.action2` at EOF                   |
| missing completions                                                | `register_completion "domain.action" "DOMAIN_ACTION"` after export |

New SCRIPT_DIR import line prepended to every file missing it.
