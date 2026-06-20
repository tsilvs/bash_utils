#!/usr/bin/env bash

# List all section names from ELF
elf.sections() {
	local elf="${1:?Usage: ${FUNCNAME[0]} ELF}"
	readelf -W -S "$elf" | awk 'match($0,/^  \[ ?[0-9]+\] +([^ ]+)/,a){print a[1]}'
}
export -f elf.sections

# Validate section name exists in ELF, return 0 if found
elf.section.exists() {
	local elf="${1:?Usage: ${FUNCNAME[0]} ELF SECTION}"
	local section="${2:?}"
	elf.sections "$elf" | grep -qxF "$section"
}
export -f elf.section.exists

# Choose a section interactively via fzf (falls back to menu if unavailable)
elf.section.choose() {
	local elf="${1:?Usage: ${FUNCNAME[0]} ELF}"
	local section

	if command -v fzf &>/dev/null; then
		section="$(elf.sections "$elf" | fzf --prompt="Select section: ")"
	else
		elf.sections "$elf" | nl
		echo -n "Enter section number: "
		local n
		read -r n
		section="$(elf.sections "$elf" | sed -n "${n}p")"
	fi
	[[ -z "$section" ]] && return 1
	echo "$section"
}
export -f elf.section.choose

# Export section binary data to file (default: /tmp/<section>.bin)
elf.section.export() {
	local elf="${1:?Usage: ${FUNCNAME[0]} ELF SECTION [OUTPUT]}"
	local section="${2:?}"
	local output="${3:-/tmp/${section}.bin}"
	local tmp
	tmp="$(mktemp)"

	if ! elf.section.exists "$elf" "$section"; then
		echo "Section '$section' not found in $elf" >&2
		rm -f "$tmp"
		return 1
	fi

	objcopy -O binary --only-section="$section" "$elf" "$output" 2>"$tmp"
	local rc=$?
	if ((rc)); then
		cat "$tmp" >&2
		rm -f "$tmp"
		return $rc
	fi
	rm -f "$tmp"
	echo "$output"
}
export -f elf.section.export

# Print strings from a specific section (or entire file if no section given)
elf.section.strings() {
	local elf="${1:?Usage: ${FUNCNAME[0]} ELF [SECTION]}"
	local section="$2"
	local min_len="${3:-4}"

	if [[ -n "$section" ]]; then
		if ! elf.section.exists "$elf" "$section"; then
			echo "Section '$section' not found in $elf" >&2
			return 1
		fi
		local tmp
		tmp="$(mktemp)"
		elf.section.export "$elf" "$section" "$tmp" >/dev/null || {
			rm -f "$tmp"
			return 1
		}
		strings -n "$min_len" "$tmp"
		rm -f "$tmp"
	else
		strings -n "$min_len" "$elf"
	fi
}
export -f elf.section.strings

# Print strings preceded by section name header
elf.section.strings.with.name() {
	local elf="${1:?Usage: ${FUNCNAME[0]} ELF SECTION}"
	local section="${2:?}"
	local min_len="${3:-4}"

	echo "=== Section: $section ==="
	elf.section.strings "$elf" "$section" "$min_len"
}
export -f elf.section.strings.with.name
