#!/usr/bin/env bash

mdlint.title_from_path() {
	local file="$1"
	local pattern="$2"
	local resolve_dot_dir="$3"
	local base filename dir1 dir2 title

	base="$(basename -- "$file")"
	filename="${base%.*}"
	dir1="$(basename -- "$(dirname -- "$file")")"
	dir2="$(basename -- "$(dirname -- "$(dirname -- "$file")")")"

	if [[ -z "$pattern" ]]; then
		if [[ "$filename" =~ ^([Rr][Ee][Aa][Dd][Mm][Ee])$ ]] && [[ -n "$dir2" && "$dir2" != "." && "$dir2" != "/" ]]; then
			pattern="{dir2}/{dir}"
		else
			pattern="{dir}/{file}"
		fi
	fi

	local rep_dir1="$dir1"
	local rep_dir2="$dir2"
	if [[ "$resolve_dot_dir" != "true" ]]; then
		[[ "$rep_dir1" == "." ]] && rep_dir1=""
		[[ "$rep_dir2" == "." ]] && rep_dir2=""
	fi

	title="$pattern"
	title="${title//\{dir2\}/$rep_dir2}"
	title="${title//\{dir\}/$rep_dir1}"
	title="${title//\{file\}/$filename}"
	title="${title//\// / }"

	title="${title//_/ }"
	title="${title//-/ }"
	title="$(echo "$title" | sed -E 's/[[:space:]]+/ /g; s/^[[:space:]/]+//; s/[[:space:]/]+$//')"
	printf '%s' "$title"
}

mdlint.path_from_input_line() {
	local line="$1"
	local path=""

	[[ -z "$line" ]] && return 1

	if [[ "$line" =~ ^(.+):[0-9]+([[:space:]]|:).* ]]; then
		path="${BASH_REMATCH[1]}"
	else
		path="$line"
	fi

	path="$(echo "$path" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
	[[ -z "$path" ]] && return 1
	printf '%s' "$path"
}

mdlint.fix.md041() {
	# Algorithm:
	# 1. Take file(s) reported to have MD041 error by `markdownlint`
	# 2. If file contains an H1 title - move it to the top
	# 3. If file doesn't contain an H1 title - either skip it or construct a title

	local deps=(awk basename cmp dirname mktemp mv sed)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			return 127 2>/dev/null || exit 127
		}
	done

	local new_title=false
	local new_title_pattern=""
	local resolve_dot_dir=false
	local files=()

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				cat <<- EOF
				Usage: ${FUNCNAME[0]} [OPTIONS] [FILES...]
				Auto-fix MD041 "First line is not title".
				
				Options:
					-h, --help              Show help
					-t, --new_title         Attempt to construct a new title. If false, command skips files without existing H1.
					--resolve-dot-dir       When {dir}/{dir2} resolves to '.', use the real dirname instead of skipping it.
					-T, --new_title_pattern Title pattern using tokens: {dir} (parent), {dir2} (grandparent), {file} (filename).
						Default: {dir}/{file} (or {dir2}/{dir} for README when grandparent exists). Sets new_title=true.
				
				Examples:
					${FUNCNAME[0]} -t README.md docs/guide.md
					${FUNCNAME[0]} -T "{dir2}/{dir}/{file}" docs/guide.md
					markdownlint "**/*.md" --ignore node_modules 2>&1 | ${FUNCNAME[0]} -t
					cat mdlint.report.MD041.paths.list | ${FUNCNAME[0]} -t
					find . -name "*.md" -print0 | xargs -0 ${FUNCNAME[0]} -t
				EOF
				return 0
				;;
			-t|--new_title)
				new_title=true
				shift
				;;
			--resolve-dot-dir)
				resolve_dot_dir=true
				shift
				;;
			-T|--new_title_pattern)
				new_title=true
				if [[ -z "$2" || "$2" == -* ]]; then
					echo "Error: --new_title_pattern requires a pattern like '{dir}/{file}'" >&2
					return 1
				fi
				new_title_pattern="$2"
				shift 2
				;;
			--)
				shift
				break
				;;
			-*)
				echo "Error: unknown option: $1" >&2
				return 1
				;;
			*)
				files+=("$1")
				shift
				;;
		esac
	done

	if [[ $# -gt 0 ]]; then
		files+=("$@")
	fi

	if [[ ${#files[@]} -eq 0 ]]; then
		if [[ -t 0 ]]; then
			echo "Error: no files provided" >&2
			return 1
		fi
		while IFS= read -r line; do
			local path
			path="$(mdlint.path_from_input_line "$line")" || continue
			files+=("$path")
		done
	fi

	for file in "${files[@]}"; do
		if [[ ! -f "$file" ]]; then
			echo "Skip: not a file: $file" >&2
			continue
		fi

		local title
		if [[ "$new_title" == "true" ]]; then
			title="$(mdlint.title_from_path "$file" "$new_title_pattern" "$resolve_dot_dir")" || return 1
		fi

		local tmp
		tmp="$(mktemp)" || return 1

		awk -v new_title="$new_title" -v title="$title" '
			{
				lines[NR]=$0
			}
			END {
				n=NR
				h1_start=0
				h1_end=0
				had_h1=0
				for (i=1; i<=n; i++) {
					if (lines[i] ~ /^#[[:space:]]+/) {
						had_h1=1
						h1_start=i
						h1_end=i
						break
					}
					if (i < n && lines[i+1] ~ /^[[:space:]]*=+[[:space:]]*$/) {
						had_h1=1
						h1_start=i
						h1_end=i+1
						break
					}
				}

				has_body=0
				for (i=1; i<=n; i++) {
					if (i >= h1_start && i <= h1_end) continue
					if (lines[i] ~ /[^[:space:]]/) {
						has_body=1
						break
					}
				}

				if (h1_start == 1) {
					for (i=1; i<=n; i++) print lines[i]
					exit 0
				}

				if (h1_start == 0) {
					if (new_title != "true") {
						for (i=1; i<=n; i++) print lines[i]
						print "__MDLINT_NO_HEADER__"
						exit 0
					}
					print "# " title
					if (has_body == 1) print ""
					printed=0
					for (i=1; i<=n; i++) {
						if (!printed && lines[i] ~ /^[[:space:]]*$/) continue
						print lines[i]
						printed=1
					}
					exit 0
				}

				for (i=h1_start; i<=h1_end; i++) print lines[i]
				if (has_body == 1) print ""
				printed=0
				for (i=1; i<=n; i++) {
					if (i >= h1_start && i <= h1_end) continue
					if (i == h1_end + 1 && lines[i] ~ /^[[:space:]]*$/) continue
					if (!printed && lines[i] ~ /^[[:space:]]*$/) continue
					print lines[i]
					printed=1
				}
			}
		' "$file" >"$tmp"

		if grep -q "__MDLINT_NO_HEADER__" "$tmp"; then
			sed -i '' -e '/__MDLINT_NO_HEADER__/d' "$tmp" 2>/dev/null || sed -i -e '/__MDLINT_NO_HEADER__/d' "$tmp"
			if cmp -s "$file" "$tmp"; then
				rm -f "$tmp"
				echo "NO_HEADER: $file"
				continue
			fi
		fi

		if cmp -s "$file" "$tmp"; then
			rm -f "$tmp"
			echo "OK: $file"
			continue
		fi

		mv "$tmp" "$file"
		echo "Fixed: $file"
	done
}
