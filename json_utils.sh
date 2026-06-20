#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

json.ls.keys() {
	local showhelp=0
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [FILE]
			List top-level JSON keys.
		EOF
		return 0
	}
	jq -r 'keys[]' "$@"
}

json.pp() {
	local showhelp=0
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [FILE]
			Pretty-print JSON with sorted keys.
		EOF
		return 0
	}
	jq -S '.' "$@"
}

json.get() {
	local showhelp=0 path=""
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		*) [[ -z "$path" ]] && {
			path="$1"
			shift
		} || break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} PATH [FILE]
			Extract value at jq PATH.
		EOF
		return 0
	}
	[[ -z "$path" ]] && {
		echo "Error: path required" >&2
		return 1
	}
	jq -r "$path" "$@"
}

export -f json.ls.keys json.pp json.get
register_simple_completion "json.ls.keys"
register_simple_completion "json.pp"
register_simple_completion "json.get"
