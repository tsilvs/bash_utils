#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

encode.img2base64() {
	local imgpath="$@"
	echo "data:image/png;base64,$(base64 -w 0 "${imgpath}")"
	return $?
}

export -f encode.img2base64
