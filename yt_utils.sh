#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

# ── yt.srt option metadata ────────────────────────────────────────────────────
_YT_SRT_OPTS_SHORT=(-h -l)
_YT_SRT_OPTS_LONG=(--help --lang)
_YT_SRT_OPTS_ARG=("" "LANG")
_YT_SRT_OPTS_DESC=("Display this help message" "Subtitle language code (default: en)")

# ── yt.mp3 option metadata ────────────────────────────────────────────────────
_YT_MP3_OPTS_SHORT=(-h)
_YT_MP3_OPTS_LONG=(--help)
_YT_MP3_OPTS_ARG=("")
_YT_MP3_OPTS_DESC=("Display this help message")

# ── yt.mp4 option metadata ────────────────────────────────────────────────────
_YT_MP4_OPTS_SHORT=(-h -q)
_YT_MP4_OPTS_LONG=(--help --quality)
_YT_MP4_OPTS_ARG=("" "FORMAT")
_YT_MP4_OPTS_DESC=("Display this help message" "yt-dlp format string")

# ── yt.chapters option metadata ───────────────────────────────────────────────
_YT_CHAPTERS_OPTS_SHORT=(-h)
_YT_CHAPTERS_OPTS_LONG=(--help)
_YT_CHAPTERS_OPTS_ARG=("")
_YT_CHAPTERS_OPTS_DESC=("Display this help message")

yt.srt() {
	dep_check yt-dlp
	local show_help=0 lang="en"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help=1
			shift
			;;
		-l | --lang)
			lang="$2"
			shift 2
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*) break ;;
		esac
	done

	eval "$(build_usage "YT_SRT" "${FUNCNAME[0]}" "URL [URL...]" "Download auto-generated subtitles as SRT.")"
	((show_help)) && {
		printf '%s\n' "$usage"
		return 0
	}

	[[ -z "${1:-}" ]] && {
		echo "Error: URL required" >&2
		return 1
	}
	yt-dlp --skip-download --write-auto-subs --write-subs --sub-lang "$lang" --convert-subs srt "$@"
}

yt.mp3() {
	dep_check yt-dlp
	local show_help=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help=1
			shift
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*) break ;;
		esac
	done

	eval "$(build_usage "YT_MP3" "${FUNCNAME[0]}" "URL [URL...]" "Download audio as MP3.")"
	((show_help)) && {
		printf '%s\n' "$usage"
		return 0
	}

	[[ -z "${1:-}" ]] && {
		echo "Error: URL required" >&2
		return 1
	}
	yt-dlp -x --audio-format mp3 "$@"
}

yt.mp4() {
	dep_check yt-dlp
	local show_help=0 quality=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help=1
			shift
			;;
		-q | --quality)
			quality="$2"
			shift 2
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*) break ;;
		esac
	done

	eval "$(build_usage "YT_MP4" "${FUNCNAME[0]}" "URL [URL...]" "Download best video+audio as MP4.")"
	((show_help)) && {
		printf '%s\n' "$usage"
		return 0
	}

	[[ -z "${1:-}" ]] && {
		echo "Error: URL required" >&2
		return 1
	}
	yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" ${quality:+-f "$quality"} "$@"
}

yt.chapters() {
	dep_check yt-dlp
	local show_help=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help=1
			shift
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*) break ;;
		esac
	done

	eval "$(build_usage "YT_CHAPTERS" "${FUNCNAME[0]}" "URL [YTDLP_ARGS...]" "Download audio split by chapters as MP3 into titled subdir.")"
	((show_help)) && {
		printf '%s\n' "$usage"
		return 0
	}

	[[ -z "${1:-}" ]] && {
		echo "Error: URL required" >&2
		return 1
	}
	local url="$1"
	shift
	local dir_name
	dir_name=$(yt-dlp --print "%(title)s" "$url") || return 1
	echo "Output: \"$dir_name\""
	mkdir -p "$dir_name" || return 1
	yt-dlp \
		--format bestaudio \
		--audio-quality 0 \
		--extract-audio \
		--audio-format mp3 \
		--download-sections "*0:00-inf" \
		--split-chapters \
		--output "chapter:%(section_number)s %(section_title)s.%(ext)s" \
		--paths "$dir_name" \
		--no-mtime \
		--no-playlist \
		"$@" "$url"
}

export -f yt.srt yt.mp3 yt.mp4 yt.chapters
register_completion "yt.srt" "YT_SRT"
register_completion "yt.mp3" "YT_MP3"
register_completion "yt.mp4" "YT_MP4"
register_completion "yt.chapters" "YT_CHAPTERS"
