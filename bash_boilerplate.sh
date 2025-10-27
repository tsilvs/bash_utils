#!/usr/bin/env bash

# fun.example() {
# 	# Check any arg for being help flag
# 	# if you need at least some options: [[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]]
# 	local usage="Usage: ${FUNCNAME[0]} ARGUMENT [OPTIONAL]
# 	--help	Displays this help message"
# 	[[ " $* " =~ ' --help ' ]] && {
# 		echo -e "${usage}"
# 		return 0
# 	}
# 	local file_path="${1:-"$(pwd)/example_file.txt"}"
# 	local lines=$(<"${file_path}")
# }

# fun.example.short() { echo "$#"; shift $(( $# - 1 )); echo "$#"; echo "$1"; }


