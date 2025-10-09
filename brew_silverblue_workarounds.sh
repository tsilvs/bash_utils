#!/usr/bin/env bash

# export TESSDATA_PREFIX="/home/linuxbrew/.linuxbrew/share/tessdata"

TESSDATA_PREFIX_BREW="/home/linuxbrew/.linuxbrew/share/tessdata"

[[ -d $TESSDATA_PREFIX_BREW ]] && {
	tesseract() {
		TESSDATA_PREFIX="$TESSDATA_PREFIX_BREW" /home/linuxbrew/.linuxbrew/bin/tesseract "$@"
		return $?
	}
}

