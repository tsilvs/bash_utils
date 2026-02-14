#!/usr/bin/env bash

pdf.flat.watermark() {
	local deps=(watermark gs magick)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			return 127 2>/dev/null || exit 127
		}
	done

	local usage="$(cat <<-EOF
		Usage: ${FUNCNAME[0]} [OPTIONS] files...
		Flattens and watermarks files.
			-h, --help            Show this help
			-w, --watermark TEXT  Watermark text (default: WATERMARK)
			-v, --verbose         Verbose messages
			-d, --dry-run         Show actions without performing them
	EOF
	)"

	local verbose=0
	local showhelp=0
	local dryrun=0
	local watermark="WATERMARK"

	# Parse options
	while (( "$#" )) && [[ "$1" == -* ]]; do
		case "$1" in
			--watermark|-w)
				if [[ $# -lt 2 || "$2" == -* ]]; then
					echo "Error: $1 requires an argument" >&2
					showhelp=1
					return 1
				fi
				watermark="$2"
				shift 2
				;;
			--verbose|-v) verbose=1; shift ;;
			--help|-h) showhelp=1; shift ;;
			--dry-run|-d) dryrun=1; shift ;;
			--) shift; break ;;
			*) echo "Unknown option: $1" >&2; showhelp=1; return 1 ;;
		esac
	done

	local files=("$@")

	[[ -z "$files" ]] && { echo "Error: files required" >&2; showhelp=1; return 1; }

	(( showhelp )) && { echo -e "${usage}"; return 0; }

	run_cmd() {
		if (( dryrun )); then
			echo "DRY-RUN: $@"
		else
			"$@"
		fi
	}

	for file in "${files[@]}"; do
		((verbose)) && echo "Processing $file"

		[[ ! -f "$file" || ! -r "$file" ]] && {
			echo "Error: cannot access $file" >&2
			continue
		}

		dir="$(dirname "$file")"
		base="$(basename "${file%.pdf}")"
		output_wmk="${dir}/${base}.wmk.pdf"
		output_flat="${dir}/${base}.wmk.flat.pdf"

		tmpdir=$(mktemp -d -p "$dir" "${base}_wmk_tmp.XXXXXX")

		((verbose)) && echo " -> Adding watermark..."
		run_cmd watermark grid "${file}" "${watermark}" -o 0.2 -a 45 -ts 50 -tc "#AAAAAA" -s "${output_wmk}"

		((verbose)) && echo " -> Flattening via PNG..."
		run_cmd gs -dNOPAUSE -dBATCH -sDEVICE=png16m -r300 -sOutputFile="${tmpdir}/page_%03d.png" "${output_wmk}"

		run_cmd magick "${tmpdir}/page_"*.png "${output_flat}"

		((verbose)) && echo "Created: ${output_flat}"

		run_cmd rm "${output_wmk}"
		run_cmd rm -rf "${tmpdir}"
	done
}

pdf.wmk() {
	pdf.flat.watermark "$@"
	return $?
}

pdf.compress() {
	local deps=(gs)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			return 127 2>/dev/null || exit 127
		}
	done

	local usage="$(cat <<-EOF
		Usage: ${FUNCNAME[0]} [OPTIONS] files...
		Compresses PDF files using Ghostscript.
			-h, --help     Show this help
	EOF
	)"

	local showhelp=0

	(( $# == 0 )) && { echo "Error: files required" >&2; echo -e "${usage}"; return 1; }

	(( showhelp )) && { echo -e "${usage}"; return 0; }

	for file in "$@"; do
		[[ ! -f "$file" || ! -r "$file" ]] && {
			echo "Error: cannot access $file" >&2
			continue
		}

		dir="$(dirname "$file")"
		base="$(basename "${file%.pdf}")"
		output="${dir}/${base}.cmp.pdf"

		gs \
			-sDEVICE=pdfwrite \
			-dCompatibilityLevel=1.4 \
			-dPDFSETTINGS=/ebook \
			-dNOPAUSE \
			-dBATCH \
			-q \
			-sOutputFile="${output}" \
			"${file}"

		echo "Compressed: ${output}"
	done
}

pdf.cmp() {
	pdf.compress "$@"
	return $?
}

export -f pdf.flat.watermark pdf.wmk pdf.compress pdf.cmp
