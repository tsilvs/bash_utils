#!/usr/bin/env bash

# --- lib ---

# List all section names from ELF
elf.sections() {
	local elf="${1:?Usage: ${FUNCNAME[0]} ELF}"
	readelf -W -S "$elf" | awk 'match($0,/^  \[ ?[0-9]+\] +([^ ]+)/,a){print a[1]}'
}
export -f elf.sections

# Return 0 if SECTION exists in ELF
elf.section.exists() {
	local elf="${1:?Usage: ${FUNCNAME[0]} ELF SECTION}"
	local section="${2:?}"
	elf.sections "$elf" | grep -qxF "$section"
}
export -f elf.section.exists

# Dump SECTION binary to OUTPUT; print output path on success
# Usage: elf.section.export ELF SECTION [OUTPUT=/tmp/<section>.bin]
elf.section.export() {
	local elf="${1:?Usage: ${FUNCNAME[0]} ELF SECTION [OUTPUT]}"
	local section="${2:?}"
	local output="${3:-/tmp/${section#.}.bin}"

	if ! elf.section.exists "$elf" "$section"; then
		echo "${FUNCNAME[0]}: '$section' not found in '$elf'" >&2
		return 1
	fi

	local errtmp
	errtmp="$(mktemp)"
	objcopy -O binary --only-section="$section" "$elf" "$output" 2>"$errtmp"
	local rc=$?
	((rc)) && cat "$errtmp" >&2
	rm -f "$errtmp"
	((rc == 0)) && echo "$output"
	return $rc
}
export -f elf.section.export

# --- interactive ---

# Interactively choose a section (fzf or numbered menu); print chosen name
elf.section.choose() {
	local elf="${1:?Usage: ${FUNCNAME[0]} ELF}"
	local section

	if command -v fzf &>/dev/null; then
		section="$(elf.sections "$elf" | fzf --prompt="section> ")"
	else
		local sections i=1
		mapfile -t sections < <(elf.sections "$elf")
		for s in "${sections[@]}"; do
			printf '%3d  %s\n' "$((i++))" "$s"
		done
		local n
		read -rp "Enter number: " n
		section="${sections[$((n - 1))]}"
	fi
	[[ -z "$section" ]] && return 1
	echo "$section"
}
export -f elf.section.choose

# --- strings ---

# Private: extract strings from one section into tmp, then clean up
_elf_strings_one() {
	local elf="$1" section="$2" min_len="$3" show_name="$4"
	local tmp
	tmp="$(mktemp)"
	elf.section.export "$elf" "$section" "$tmp" >/dev/null || {
		rm -f "$tmp"
		return 1
	}
	((show_name)) && echo "=== $section ==="
	strings -n "$min_len" "$tmp"
	rm -f "$tmp"
}

# Print strings from ELF — entire file, one section, or all sections
#
# Usage: elf.strings [OPTIONS] ELF
#   --section NAME        Strings from named section only
#   --all-sections        Strings from every section
#   --show-section-name   Print "=== NAME ===" header before each block
#   --min-len N           Minimum printable string length (default: 4)
elf.strings() {
	local section="" all_sections=0 show_name=0 min_len=4 elf=""

	while (($#)); do
		case "$1" in
		--section)
			section="${2:?--section requires NAME}"
			shift 2
			;;
		--all-sections)
			all_sections=1
			shift
			;;
		--show-section-name)
			show_name=1
			shift
			;;
		--min-len)
			min_len="${2:?--min-len requires N}"
			shift 2
			;;
		--help | -h)
			cat <<-'EOF'
				Usage: elf.strings [OPTIONS] ELF
				  --section NAME        Strings from named section
				  --all-sections        Strings from every section
				  --show-section-name   Header before each output block
				  --min-len N           Minimum string length (default: 4)
			EOF
			return 0
			;;
		--)
			shift
			elf="${1:?ELF required after --}"
			shift
			;;
		-*)
			echo "${FUNCNAME[0]}: unknown option '$1'" >&2
			return 1
			;;
		*)
			elf="$1"
			shift
			;;
		esac
	done

	: "${elf:?Usage: ${FUNCNAME[0]} [OPTIONS] ELF}"

	if ((all_sections)); then
		while IFS= read -r sec; do
			_elf_strings_one "$elf" "$sec" "$min_len" "$show_name"
		done < <(elf.sections "$elf")
	elif [[ -n "$section" ]]; then
		if ! elf.section.exists "$elf" "$section"; then
			echo "${FUNCNAME[0]}: '$section' not found in '$elf'" >&2
			return 1
		fi
		_elf_strings_one "$elf" "$section" "$min_len" "$show_name"
	else
		((show_name)) && echo "=== $elf ==="
		strings -n "$min_len" "$elf"
	fi
}
export -f elf.strings

# --- completions ---

_elf_strings_complete() {
	local cur prev
	_init_completion 2>/dev/null || {
		cur="${COMP_WORDS[COMP_CWORD]}"
		prev="${COMP_WORDS[COMP_CWORD - 1]}"
	}

	case "$prev" in
	--section)
		local elf w
		for w in "${COMP_WORDS[@]}"; do
			[[ -f "$w" ]] && {
				elf="$w"
				break
			}
		done
		[[ -n "$elf" ]] && {
			local secs
			mapfile -t secs < <(elf.sections "$elf" 2>/dev/null)
			COMPREPLY=($(compgen -W "${secs[*]}" -- "$cur"))
		}
		return
		;;
	--min-len)
		COMPREPLY=($(compgen -W "4 8 10 16" -- "$cur"))
		return
		;;
	esac

	if [[ "$cur" == -* ]]; then
		COMPREPLY=($(compgen -W "--section --all-sections --show-section-name --min-len --help" -- "$cur"))
		return
	fi
	_filedir 2>/dev/null || COMPREPLY=($(compgen -f -- "$cur"))
}

# Completion for (ELF [SECTION ...]) positional functions
_elf_section_arg2_complete() {
	local cur prev
	_init_completion 2>/dev/null || {
		cur="${COMP_WORDS[COMP_CWORD]}"
		prev="${COMP_WORDS[COMP_CWORD - 1]}"
	}
	local cword="${COMP_CWORD:-0}"

	if ((cword == 1)); then
		_filedir 2>/dev/null || COMPREPLY=($(compgen -f -- "$cur"))
	elif ((cword >= 2)); then
		local elf="${COMP_WORDS[1]}"
		if [[ -f "$elf" ]]; then
			local secs
			mapfile -t secs < <(elf.sections "$elf" 2>/dev/null)
			COMPREPLY=($(compgen -W "${secs[*]}" -- "$cur"))
		else
			_filedir 2>/dev/null || COMPREPLY=($(compgen -f -- "$cur"))
		fi
	fi
}

_elf_file_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	_filedir 2>/dev/null || COMPREPLY=($(compgen -f -- "$cur"))
}

complete -F _elf_strings_complete elf.strings
complete -F _elf_section_arg2_complete elf.section.exists elf.section.export
complete -F _elf_file_complete elf.sections elf.section.choose
