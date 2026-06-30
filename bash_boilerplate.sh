#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

# fun.example() {
# 	local showhelp=0
# 	while (( $# )) && [[ "$1" == -* ]]; do
# 		case "$1" in
# 			--help|-h) showhelp=1; shift ;;
# 			--*) echo "Unknown option: $1" >&2; return 1 ;;
# 			*) break ;;
# 		esac
# 	done
# 	(( showhelp )) && {
# 		cat <<-EOF
# 		Usage: ${FUNCNAME[0]} ARGUMENT [OPTIONAL]
# 		  --help  Show this help
# 		EOF
# 		return 0
# 	}
# 	local file_path="${1:-"$(pwd)/example_file.txt"}"
# 	local lines=$(<"${file_path}")
# }
#
# export -f fun.example
