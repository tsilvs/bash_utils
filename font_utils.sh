#!/bin/bash

font.name() {
	local font_file="${1}"; [[ -z "${font_file}" ]] && { echo "Font file is required"; return 1; }
	fc-query -f '%{family}\n' "${font_file}"
}

font.ls.names() {
	local font_dir="${1:-"/usr/share/fonts"}"; [[ -z "${font_dir}" ]] && { echo "Font directory is required"; return 1; }
	find "${font_dir}" -type f -name '*.ttf' -o -name '*.otf' | while read -r font_file; do
		font.name "${font_file}"
	done
}