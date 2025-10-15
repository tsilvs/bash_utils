#!/usr/bin/env bash

pdf.flat.watermark() {
	set -o errexit
	set -o pipefail
	set -o nounset

	local usage="Usage: ${FUNCNAME[0]} [OPTIONS] files...
Flattens and watermarks files.
	-w, --watermark [text]  Watermark text
	-v, --verbose           Verbose messages
	-h, --help              Show this help
"
	# -d, --dry-run    Show planned actions without changes to the system
	local verbose=0
	local showhelp=0
	# local dryrun=0
	local watermark="WATERMARK"
	local files=("")

	# Parse options
	while (( "$#" )); do
		case "$1" in
			--watermark|-w) watermark="${2}"; shift 2 ;;
			--verbose|-V) verbose=1; shift 1 ;;
			--help|-h) showhelp=1; shift 1 ;;
			# --dry-run|-d) dryrun=1; shift 1 ;;
		esac
	done

	local files=("$@")

	# [[ -z "$watermark" ]] && { echo "Error: watermark required"; showhelp=1; return 1; }
	[[ -z "$files" ]] && { echo "Error: files required"; showhelp=1; return 1; }

	(( showhelp )) && { echo -e "${usage}"; return 0; }

	for file in "${files[@]}"; do
		dir="$(dirname "$file")"
		base="$(basename "${file%.pdf}")"
		output_wmk="${dir}/${base}.wmk.pdf"
		output_flat="${dir}/${base}.wmk.flat.pdf"

		watermark grid "${file}" "${watermark}" -o 0.2 -a 45 -ts 50 -tc "#AAAAAA" -s "${output_wmk}"

		gs -dNOPAUSE -dBATCH -sDEVICE=png16m -r300 -sOutputFile="${dir}/${base}_tmp_page_%03d.png" "${output_wmk}"

		magick "${dir}/${base}_tmp_page_"*.png "${output_flat}"
		# mkdir -p ~/Desktop/upload
		# cp "${output_flat}" ~/Desktop/upload

		rm "${output_wmk}"
		rm "${dir}/${base}_tmp_page_"*.png
	done
}

# pdf.cmp() {
# 	local filename
# 	gs \
# 		-sDEVICE=pdfwrite \
# 		-dCompatibilityLevel=1.4 \
# 		-dPDFSETTINGS=/prepress \
# 		-dPDFSETTINGS=/ebook \
# 		-dNOPAUSE \
# 		-dQUIET \
# 		-dBATCH \
# 		-sOutputFile=${filename}.cmp.pdf \
# 		${filename}.pdf
# }

