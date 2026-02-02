#!/usr/bin/env bash

diff.right() {
	local deps=(diff)
	local file_left="" file_right=""

	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			return 127 2>/dev/null || exit 127
		}
	done

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				cat <<-EOF
				Usage: ${FUNCNAME[0]} [OPTIONS] LEFT RIGHT
				Show only right-file changes.

				Options:
				  -L, --file_left   path   Left file
				  -R, --file_right  path   Right file
				  -h, --help               Show help

				Example:
				  ${FUNCNAME[0]} -L a.txt -R b.txt
				EOF
				return 0
				;;
			-L|--file_left)
				[[ -n "$2" ]] || { echo "Error: --file_left requires argument" >&2; return 1; }
				file_left="$2"
				shift 2
				;;
			-R|--file_right)
				[[ -n "$2" ]] || { echo "Error: --file_right requires argument" >&2; return 1; }
				file_right="$2"
				shift 2
				;;
			*)
				[[ $# -ge 2 ]] || { echo "Error: require LEFT RIGHT" >&2; return 1; }
				file_left="$1"
				file_right="$2"
				shift 2
				;;
		esac
	done

	[[ -z "$file_left" ]]  && { echo "Error: Left file not specified." >&2; return 1; }
	[[ -z "$file_right" ]] && { echo "Error: Right file not specified." >&2; return 1; }

	diff \
		--unchanged-line-format= \
		--old-line-format= \
		--new-line-format='%L' \
		"$file_left" "$file_right"
}

export -f diff.right
