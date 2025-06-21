#!/bin/bash
#local install_dir_rel="$(realpath $(dirname "${BASH_SOURCE[0]}"))"
#echo "$(realpath $(dirname "${BASH_SOURCE[0]}"))"
#echo "$(dirname "${BASH_SOURCE[0]}")"
#echo "${BASH_SOURCE[0]}"

#usage() {
#	local cmd
#	local args_json
#	local i18n_json
#}

# Suntax notes
# local y="Hello"; local x="y"; echo ${!x};
#to unset multiple environment variables grouped by prefix, e.g `unset ${!DOCKER*}`

#div_and_rem() {
#	local x=$1
#	local y=$2
#	local int=$3
#	local remainder=$4
#
#	export $int=$(($x / $y))
#	export $remainder=$(($x % $y))
#}
#
#declare i r
#
#div_and_rem 10 3 i r
#
#echo $i - $r

