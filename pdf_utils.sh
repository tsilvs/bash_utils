#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

pdf.flat() {
	local deps=(gs magick)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			return 127 2>/dev/null || exit 127
		}
	done

	local usage="$(
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [OPTIONS] files...
			Flattens PDF files by rasterizing pages and reassembling them.
				-h, --help            Show this help
				-v, --verbose         Verbose messages
				-d, --dry-run         Show actions without performing them
				-r, --resolution DPI  Rasterization resolution (default: 300)
		EOF
	)"

	local verbose=0
	local showhelp=0
	local dryrun=0
	local resolution=300

	# Parse options
	while (("$#")) && [[ "$1" == -* ]]; do
		case "$1" in
		--resolution | -r)
			if [[ $# -lt 2 || "$2" == -* ]]; then
				echo "Error: $1 requires an argument" >&2
				showhelp=1
				return 1
			fi
			resolution="$2"
			shift 2
			;;
		--verbose | -v)
			verbose=1
			shift
			;;
		--help | -h)
			showhelp=1
			shift
			;;
		--dry-run | -d)
			dryrun=1
			shift
			;;
		--)
			shift
			break
			;;
		*)
			echo "Unknown option: $1" >&2
			showhelp=1
			return 1
			;;
		esac
	done

	local files=("$@")

	[[ -z "$files" ]] && {
		echo "Error: files required" >&2
		showhelp=1
		return 1
	}

	((showhelp)) && {
		echo -e "${usage}"
		return 0
	}

	eval "$(dry_run_wrapper)"

	for file in "${files[@]}"; do
		((verbose)) && echo "Processing $file"

		[[ ! -f "$file" || ! -r "$file" ]] && {
			echo "Error: cannot access $file" >&2
			continue
		}

		dir="$(dirname "$file")"
		base="$(basename "${file%.pdf}")"
		output_flat="${dir}/${base}.flat.pdf"

		tmpdir=$(mktemp -d -p "$dir" "${base}_flat_tmp.XXXXXX")

		((verbose)) && echo " -> Flattening via PNG..."
		run_cmd gs -dNOPAUSE -dBATCH -sDEVICE=png16m -r"${resolution}" -sOutputFile="${tmpdir}/page_%03d.png" "${file}"
		run_cmd magick "${tmpdir}/page_"*.png "${output_flat}"

		((verbose)) && echo "Created: ${output_flat}"

		run_cmd rm -rf "${tmpdir}"
	done
}

pdf.flat.watermark() {
	local deps=(watermark)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			return 127 2>/dev/null || exit 127
		}
	done

	local usage="$(
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [OPTIONS] files...
			Watermarks and flattens PDF files.
				-h, --help            Show this help
				-w, --watermark TEXT  Watermark text (default: WATERMARK)
				-v, --verbose         Verbose messages
				-d, --dry-run         Show actions without performing them
				-r, --resolution DPI  Rasterization resolution (default: 300)
		EOF
	)"

	local verbose=0
	local showhelp=0
	local dryrun=0
	local watermark="WATERMARK"
	local resolution=300

	# Parse options
	while (("$#")) && [[ "$1" == -* ]]; do
		case "$1" in
		--watermark | -w)
			if [[ $# -lt 2 || "$2" == -* ]]; then
				echo "Error: $1 requires an argument" >&2
				showhelp=1
				return 1
			fi
			watermark="$2"
			shift 2
			;;
		--resolution | -r)
			if [[ $# -lt 2 || "$2" == -* ]]; then
				echo "Error: $1 requires an argument" >&2
				showhelp=1
				return 1
			fi
			resolution="$2"
			shift 2
			;;
		--verbose | -v)
			verbose=1
			shift
			;;
		--help | -h)
			showhelp=1
			shift
			;;
		--dry-run | -d)
			dryrun=1
			shift
			;;
		--)
			shift
			break
			;;
		*)
			echo "Unknown option: $1" >&2
			showhelp=1
			return 1
			;;
		esac
	done

	local files=("$@")

	[[ -z "$files" ]] && {
		echo "Error: files required" >&2
		showhelp=1
		return 1
	}

	((showhelp)) && {
		echo -e "${usage}"
		return 0
	}

	eval "$(dry_run_wrapper)"

	local flat_args=()
	((verbose)) && flat_args+=(--verbose)
	((dryrun)) && flat_args+=(--dry-run)
	flat_args+=(--resolution "${resolution}")

	for file in "${files[@]}"; do
		((verbose)) && echo "Processing $file"

		[[ ! -f "$file" || ! -r "$file" ]] && {
			echo "Error: cannot access $file" >&2
			continue
		}

		dir="$(dirname "$file")"
		base="$(basename "${file%.pdf}")"
		output_wmk="${dir}/${base}.wmk.pdf"

		((verbose)) && echo " -> Adding watermark..."
		run_cmd watermark grid "${file}" "${watermark}" -o 0.2 -a 45 -ts 50 -tc "#AAAAAA" -s "${output_wmk}"

		((verbose)) && echo " -> Flattening via PNG..."
		pdf.flat "${flat_args[@]}" -- "${output_wmk}"

		run_cmd rm "${output_wmk}"
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

	local usage="$(
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [OPTIONS] files...
			Compresses PDF files using Ghostscript.
				-h, --help                 Show this help
				-r, --resolution DPI       Color/gray image resolution (default: 120)
				-q, --jpeg-quality QUALITY JPEG quality 0-100 (default: 60, forces re-encode)
				-p, --preset NAME          PDF preset (/screen,/ebook,/printer,/prepress) (default: /screen)
				-g, --grayscale            Convert pages to grayscale
				-R, --rasterize            Rasterize pages to JPEGs before rebuilding PDF
		EOF
	)"

	local showhelp=0
	local color_res=120
	local gray_res=120
	local mono_res=300
	local jpeg_quality=60
	local pdfsettings="/screen"
	local grayscale=0
	local rasterize=0

	while (("$#")) && [[ "$1" == -* ]]; do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		--grayscale | -g)
			grayscale=1
			shift
			;;
		--rasterize | -R)
			rasterize=1
			shift
			;;
		--resolution | -r)
			if [[ $# -lt 2 || "$2" == -* ]]; then
				echo "Error: $1 requires an argument" >&2
				showhelp=1
				return 1
			fi
			color_res="$2"
			gray_res="$2"
			shift 2
			;;
		--jpeg-quality | -q)
			if [[ $# -lt 2 || "$2" == -* ]]; then
				echo "Error: $1 requires an argument" >&2
				showhelp=1
				return 1
			fi
			jpeg_quality="$2"
			shift 2
			;;
		--preset | -p)
			if [[ $# -lt 2 || "$2" == -* ]]; then
				echo "Error: $1 requires an argument" >&2
				showhelp=1
				return 1
			fi
			pdfsettings="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			echo "Unknown option: $1" >&2
			showhelp=1
			return 1
			;;
		esac
	done

	((showhelp)) && {
		echo -e "${usage}"
		return 0
	}

	(($# == 0)) && {
		echo "Error: files required" >&2
		echo -e "${usage}"
		return 1
	}

	local color_args=()
	if ((grayscale)); then
		color_args=(
			-sProcessColorModel=DeviceGray
			-sColorConversionStrategy=Gray
			-dOverrideICC
		)
	fi

	for file in "$@"; do
		[[ ! -f "$file" || ! -r "$file" ]] && {
			echo "Error: cannot access $file" >&2
			continue
		}

		dir="$(dirname "$file")"
		base="$(basename "${file%.pdf}")"
		output="${dir}/${base}.cmp.pdf"

		if ((rasterize)); then
			command -v magick >/dev/null 2>&1 || {
				echo "Error: dependency missing: magick" >&2
				continue
			}

			local device="jpeg"
			if ((grayscale)); then
				device="jpeggray"
			fi

			local tmpdir
			tmpdir=$(mktemp -d -p "$dir" "${base}_cmp_tmp.XXXXXX")

			gs \
				-dNOPAUSE \
				-dBATCH \
				-sDEVICE="${device}" \
				-r"${color_res}" \
				-dJPEGQ="${jpeg_quality}" \
				-sOutputFile="${tmpdir}/page_%03d.jpg" \
				"${file}"

			magick "${tmpdir}/page_"*.jpg -quality "${jpeg_quality}" "${output}"

			rm -rf "${tmpdir}"
			echo "Compressed: ${output}"
			continue
		fi

		gs \
			-sDEVICE=pdfwrite \
			-dCompatibilityLevel=1.4 \
			-dPDFSETTINGS="${pdfsettings}" \
			-dDetectDuplicateImages=true \
			-dAutoFilterColorImages=false \
			-dAutoFilterGrayImages=false \
			-dEncodeColorImages=true \
			-dEncodeGrayImages=true \
			-dColorImageFilter=/DCTEncode \
			-dDownsampleColorImages=true \
			-dColorImageDownsampleThreshold=1.0 \
			-dColorImageDownsampleType=/Average \
			-dColorImageResolution="${color_res}" \
			-dGrayImageFilter=/DCTEncode \
			-dDownsampleGrayImages=true \
			-dGrayImageDownsampleThreshold=1.0 \
			-dGrayImageDownsampleType=/Average \
			-dGrayImageResolution="${gray_res}" \
			-dDownsampleMonoImages=true \
			-dMonoImageDownsampleThreshold=1.0 \
			-dMonoImageResolution="${mono_res}" \
			-dJPEGQ="${jpeg_quality}" \
			-dPassThroughJPEGImages=false \
			-dPassThroughJPXImages=false \
			"${color_args[@]}" \
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

export -f pdf.flat pdf.flat.watermark pdf.wmk pdf.compress pdf.cmp
register_simple_completion "pdf.flat" "-r" "--resolution" "-v" "--verbose" "-d" "--dry-run"
register_simple_completion "pdf.flat.watermark"
register_simple_completion "pdf.wmk"
register_simple_completion "pdf.compress"
register_simple_completion "pdf.cmp"
