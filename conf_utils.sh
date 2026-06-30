#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

conf.set() {
	local showhelp=0
	while (("$#")) && [[ "$1" == -* ]]; do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		--*)
			echo "Unknown option: $1" >&2
			showhelp=1
			return 1
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		echo "Usage: ${FUNCNAME[0]} [OPTIONS] key value file"
		return 0
	}

	local conf_file="${1:?"Conf file is required"}"
	local key="${2:?"Key is required"}"
	local value="${3:?"Value is required"}"
	[[ ! $(grep -q "^${key}=" "${conf_file}") ]] && {
		echo "${key}=${value}" >>"${conf_file}"
		return 0
	}
	sed -i "s/^${key}=.*/${key}=${value}/" "${conf_file}"
}

export -f conf.set
register_simple_completion "conf.set"
