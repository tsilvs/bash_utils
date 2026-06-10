#!/usr/bin/env bash

# source "$(dirname "${BASH_SOURCE[0]}")/lib/fn.sh"

# txt.wmk.rm option definitions (parallel arrays — reused in usage + completion)
# index:                          0            1          2           3
_TXT_WMK_RM_OPTS_SHORT=(-i -o -n -h)
_TXT_WMK_RM_OPTS_LONG=(--inplace --output --dry-run --help)
_TXT_WMK_RM_OPTS_ARG=("" "FILE" "" "")
_TXT_WMK_RM_OPTS_DESC=(
	"Edit file(s) in-place (file mode only)"
	"Write to FILE (single file mode only)"
	"Print command without executing"
	"Show help"
)

# txt.wmk.rm: remove invisible watermark chars (U+200B, U+00A0, U+FEFF, U+200C, U+200D)
txt.wmk.rm() {
	local deps=(sed)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			return 127 2>/dev/null || exit 127
		}
	done

	local inplace=0 dryrun=0 showhelp=0 output=""

	# Build options block from parallel arrays
	local usage_opts="" i
	for ((i = 0; i < ${#_TXT_WMK_RM_OPTS_SHORT[@]}; i++)); do
		local sig="${_TXT_WMK_RM_OPTS_SHORT[$i]}, ${_TXT_WMK_RM_OPTS_LONG[$i]}${_TXT_WMK_RM_OPTS_ARG[$i]:+ ${_TXT_WMK_RM_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t\t%-26s%s\n' "$sig" "${_TXT_WMK_RM_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] [FILE|STRING...]
Remove invisible watermark characters from text.

Input modes (auto-detected):
	stdin      echo \"text\" | $fn
	           cat file.txt | $fn
	file(s)    $fn file.txt [file2.txt ...]
	proc-sub   $fn <(cat file.txt)
	string     $fn \"literal text with watermarks\"

Options:
$usage_opts
Examples:
	echo \"text\" | $fn > clean.txt
	$fn -i input.txt
	$fn -o output.txt input.txt
	$fn \"hello​world\""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-i | --inplace)
			inplace=1
			shift
			;;
		-o | --output)
			output="$2"
			shift 2
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		*)
			break
			;;
		esac
	done

	run_cmd() {
		if ((dryrun)); then
			echo "DRY-RUN: $*"
		else
			"$@"
		fi
	}

	((showhelp)) && {
		echo -e "${usage}"
		return 0
	}

	local files=("$@")

	local sed_args=(
		-e 's/\xe2\x80\x8b//g'
		-e 's/\xc2\xa0/ /g'
		-e 's/\xef\xbb\xbf//g'
		-e 's/\xe2\x80\x8c//g'
		-e 's/\xe2\x80\x8d//g'
	)

	if [[ ${#files[@]} -eq 0 ]]; then
		# stdin mode
		run_cmd sed "${sed_args[@]}"
	elif [[ -e "${files[0]}" ]]; then
		# file / process-substitution mode
		if ((inplace)); then
			run_cmd sed -i "${sed_args[@]}" "${files[@]}"
		elif [[ -n "$output" ]]; then
			[[ ${#files[@]} -gt 1 ]] && {
				echo "Error: --output requires single input file" >&2
				return 1
			}
			if ((dryrun)); then
				echo "DRY-RUN: sed ${sed_args[*]} ${files[0]} > $output"
			else
				sed "${sed_args[@]}" "${files[0]}" >"$output"
			fi
		else
			run_cmd sed "${sed_args[@]}" "${files[@]}"
		fi
	else
		# literal string mode
		if ((dryrun)); then
			echo "DRY-RUN: printf '%s' \"${files[*]}\" | sed ${sed_args[*]}"
		else
			printf '%s' "${files[*]}" | sed "${sed_args[@]}"
		fi
	fi
}

export -f txt.wmk.rm

_txt.wmk.rm_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_TXT_WMK_RM_OPTS_SHORT[@]}" "${_TXT_WMK_RM_OPTS_LONG[@]}")
	case "$cur" in
	-*)
		COMPREPLY=($(compgen -W "${all_opts[*]}" -- "$cur"))
		;;
	*)
		COMPREPLY=($(compgen -f -- "$cur"))
		;;
	esac
}
complete -F _txt.wmk.rm_complete txt.wmk.rm
