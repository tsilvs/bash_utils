#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

yt.srt() {
	dep_check yt-dlp
	local showhelp=0 lang="en"
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		--lang)
			lang="$2"
			shift 2
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [--lang LANG] URL [URL...]
			Download auto-generated subtitles as SRT.
		EOF
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
	local showhelp=0
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} URL [URL...]
			Download audio as MP3.
		EOF
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
	local showhelp=0 quality=""
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		--quality | -q)
			quality="$2"
			shift 2
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [--quality FORMAT] URL [URL...]
			Download best video+audio as MP4.
		EOF
		return 0
	}
	[[ -z "${1:-}" ]] && {
		echo "Error: URL required" >&2
		return 1
	}
	yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" ${quality:+-f "$quality"} "$@"
}

export -f yt.srt yt.mp3 yt.mp4
register_simple_completion "yt.srt" "--lang"
register_simple_completion "yt.mp3"
register_simple_completion "yt.mp4" "-q" "--quality"
