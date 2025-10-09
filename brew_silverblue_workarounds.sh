#!/usr/bin/env bash

# export TESSDATA_PREFIX="/home/linuxbrew/.linuxbrew/share/tessdata"

TESSDATA_PREFIX="/home/linuxbrew/.linuxbrew/share/tessdata"

[[ -d $TESSDATA_PREFIX ]] && {
	tesseract() {
		TESSDATA_PREFIX=$TESSDATA_PREFIX /home/linuxbrew/.linuxbrew/bin/tesseract "$@"
		return $?
	}
}

