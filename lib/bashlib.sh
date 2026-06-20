#!/usr/bin/env bash

# ─── Core Utilities ──────────────────────────────────────────────────────────
# Stateless utilities used across all utility scripts.

# ── Dependency check ─────────────────────────────────────────────────────────
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

# ── Dry-run wrapper ──────────────────────────────────────────────────────────
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

# ── File validation ──────────────────────────────────────────────────────────
# Usage: validate_input "$file" || return
validate_input() {
	[[ -f "$1" && -r "$1" ]] && return 0
	echo "Error: cannot access $1" >&2
	return 1
}

# ── Extension check ─────────────────────────────────────────────────────────
# Usage: ext_check "file.mkv" "${_EXTS[@]}" || return
ext_check() {
	local file="$1" ext
	shift
	ext="${file##*.}"
	ext="${ext,,}"
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
