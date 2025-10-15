#!/usr/bin/env bash

img2base64() {
	local imgpath="$@"
	echo "data:image/png;base64,$(base64 -w 0 "${imgpath}")"
	return $?
}

