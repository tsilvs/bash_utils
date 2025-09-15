#!/usr/bin/env bash

#function_example() {
#	# Check any arg for being help flag
#	# if you need at least some options: [[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]]
#	[[ " $* " =~ ' --help ' ]] && {
#		echo -e "Usage: function_example ARGUMENT [OPTIONAL]
#	--help	Displays this help message";
#		return 0;
#	}
#	local file_path="${1:-"$(pwd)/example_file.txt"}"
#	local lines=$(<"${file_path}")
#}

#le_func() { echo "$#"; shift $(( $# - 1 )); echo "$#"; echo "$1"; }