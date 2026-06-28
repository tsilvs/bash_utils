#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/bashlib.sh"

# Shared: supported video extensions
_FFMPEG_VIDEO_EXTS=("mp4" "mkv" "avi" "mov" "flv" "wmv" "webm" "m4v" "mpg" "mpeg")

# ── ffmpeg.video.speed option metadata ───────────────────────────────────────
#                                              0           1          2          3
_FFMPEG_VIDEO_SPEED_OPTS_SHORT=(-s -o -n -h)
_FFMPEG_VIDEO_SPEED_OPTS_LONG=(--speed --output --dry-run --help)
_FFMPEG_VIDEO_SPEED_OPTS_ARG=("FACTOR" "FILE" "" "")
_FFMPEG_VIDEO_SPEED_OPTS_DESC=(
	"Speed multiplier (default: 1.5)"
	"Output path (single input only; default: INPUT_SPEEDx.mp4)"
	"Print command without executing"
	"Show help"
)

# ffmpeg.video.speed: re-encode video at given playback speed multiplier
# Handles atempo chaining for factors outside [0.5, 2.0]
ffmpeg.video.speed() {
	local deps=(ffmpeg awk)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local speed="1.5" output="" dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_VIDEO_SPEED_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_VIDEO_SPEED_OPTS_SHORT[$i]}, ${_FFMPEG_VIDEO_SPEED_OPTS_LONG[$i]}${_FFMPEG_VIDEO_SPEED_OPTS_ARG[$i]:+ ${_FFMPEG_VIDEO_SPEED_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_FFMPEG_VIDEO_SPEED_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] FILE [FILE...]
Re-encode video at given speed multiplier. Output: INPUT_SPEEDx.mp4.

Supported extensions: ${_FFMPEG_VIDEO_EXTS[*]}

Options:
$usage_opts
Examples:
	$fn video.mkv
	$fn -s 2 *.mkv
	$fn -s 0.75 -o slow.mp4 clip.mp4"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-s | --speed)
			speed="$2"
			shift 2
			;;
		-o | --output)
			output="$2"
			shift 2
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		*) break ;;
		esac
	done

	eval "$(dry_run_wrapper)"

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}
	[[ $# -eq 0 ]] && {
		echo "Error: no input file" >&2
		return 1
	}
	[[ -n "$output" && $# -gt 1 ]] && {
		echo "Error: --output requires single input" >&2
		return 1
	}

	# Build atempo filter chain; each stage clamped to [0.5, 2.0]
	local atempo_chain
	atempo_chain=$(awk -v s="$speed" 'BEGIN {
		chain = ""; rem = s
		while (rem > 2.0) { chain = chain "atempo=2.0,"; rem /= 2.0 }
		while (rem < 0.5) { chain = chain "atempo=0.5,"; rem *= 2.0 }
		printf "%satempo=%.6g", chain, rem
	}')
	local pts_factor
	pts_factor=$(awk -v s="$speed" 'BEGIN { printf "%.6g", 1/s }')

	local ret=0
	for input in "$@"; do
		[[ ! -f "$input" ]] && {
			echo "Skip: $input (not found)" >&2
			ret=1
			continue
		}
		local ext="${input##*.}"
		ext="${ext,,}"
		local valid=0
		for e in "${_FFMPEG_VIDEO_EXTS[@]}"; do [[ "$ext" == "$e" ]] && {
			valid=1
			break
		}; done
		((!valid)) && {
			echo "Skip: $input (unsupported: $ext)" >&2
			ret=1
			continue
		}

		local out="${output:-${input%.*}_${speed}x.mp4}"

		run_cmd ffmpeg -i "$input" \
			-vf "setpts=${pts_factor}*PTS,pad=ceil(iw/2)*2:ceil(ih/2)*2,scale=trunc(iw/2)*2:trunc(ih/2)*2" \
			-af "$atempo_chain" \
			-c:v libx264 -profile:v baseline -level 3.0 -pix_fmt yuv420p \
			-c:a aac -b:a 128k -ar 48000 \
			-movflags +faststart -y "$out" || {
			echo "Error: ffmpeg failed: $input" >&2
			ret=1
		}
	done
	return $ret
}
export -f ffmpeg.video.speed

_ffmpeg.video.speed_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_VIDEO_SPEED_OPTS_SHORT[@]}" "${_FFMPEG_VIDEO_SPEED_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*) mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.video.speed_complete ffmpeg.video.speed

# ── ffmpeg.video.mp4 option metadata ─────────────────────────────────────────
#                                            0          1        2       3          4
_FFMPEG_VIDEO_MP4_OPTS_SHORT=(-o -q -f -n -h)
_FFMPEG_VIDEO_MP4_OPTS_LONG=(--output --quality --force --dry-run --help)
_FFMPEG_VIDEO_MP4_OPTS_ARG=("FILE" "PRESET" "" "" "")
_FFMPEG_VIDEO_MP4_OPTS_DESC=(
	"Output path (single input only; default: INPUT.mp4)"
	"FFmpeg preset: ultrafast fast medium slow veryslow (default: medium)"
	"Overwrite output if exists"
	"Print command without executing"
	"Show help"
)

# ffmpeg.video.mp4: convert video to mp4 (libx264 + aac)
ffmpeg.video.mp4() {
	local deps=(ffmpeg)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local output="" quality="medium" force=0 dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_VIDEO_MP4_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_VIDEO_MP4_OPTS_SHORT[$i]}, ${_FFMPEG_VIDEO_MP4_OPTS_LONG[$i]}${_FFMPEG_VIDEO_MP4_OPTS_ARG[$i]:+ ${_FFMPEG_VIDEO_MP4_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_FFMPEG_VIDEO_MP4_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] FILE [FILE...]
Convert video file(s) to MP4 (libx264 + AAC).

Supported extensions: ${_FFMPEG_VIDEO_EXTS[*]}

Options:
$usage_opts
Examples:
	$fn video.mkv
	$fn -q slow *.avi
	$fn -o out.mp4 clip.webm"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-o | --output)
			output="$2"
			shift 2
			;;
		-q | --quality)
			quality="$2"
			shift 2
			;;
		-f | --force)
			force=1
			shift
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		*) break ;;
		esac
	done

	eval "$(dry_run_wrapper)"

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}
	[[ $# -eq 0 ]] && {
		echo "Error: no input file" >&2
		return 1
	}
	[[ -n "$output" && $# -gt 1 ]] && {
		echo "Error: --output requires single input" >&2
		return 1
	}

	local ret=0
	for input in "$@"; do
		[[ ! -f "$input" ]] && {
			echo "Skip: $input (not found)" >&2
			ret=1
			continue
		}
		local ext="${input##*.}"
		ext="${ext,,}"
		local valid=0
		for e in "${_FFMPEG_VIDEO_EXTS[@]}"; do [[ "$ext" == "$e" ]] && {
			valid=1
			break
		}; done
		((!valid)) && {
			echo "Skip: $input (unsupported: $ext)" >&2
			ret=1
			continue
		}

		local out="${output:-${input%.*}.mp4}"
		if [[ -f "$out" ]] && ((!force)); then
			echo "Skip: $out exists (use -f to overwrite)" >&2
			ret=1
			continue
		fi

		run_cmd ffmpeg -i "$input" \
			-c:v libx264 -preset "$quality" \
			-c:a aac \
			-movflags +faststart \
			${force:+-y} "$out" || {
			echo "Error: ffmpeg failed: $input" >&2
			ret=1
		}
	done
	return $ret
}
export -f ffmpeg.video.mp4

_ffmpeg.video.mp4_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_VIDEO_MP4_OPTS_SHORT[@]}" "${_FFMPEG_VIDEO_MP4_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*) mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.video.mp4_complete ffmpeg.video.mp4

# ── ffmpeg.video.wav option metadata ─────────────────────────────────────────
#                                            0          1          2       3
_FFMPEG_VIDEO_WAV_OPTS_SHORT=(-o -r -n -h)
_FFMPEG_VIDEO_WAV_OPTS_LONG=(--output --rate --dry-run --help)
_FFMPEG_VIDEO_WAV_OPTS_ARG=("FILE" "HZ" "" "")
_FFMPEG_VIDEO_WAV_OPTS_DESC=(
	"Output path (single input only; default: INPUT.wav)"
	"Sample rate in Hz (default: 16000)"
	"Print command without executing"
	"Show help"
)

# ffmpeg.video.wav: extract audio track as 16-bit PCM WAV (whisper-compatible defaults)
ffmpeg.video.wav() {
	local deps=(ffmpeg)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local output="" rate="16000" dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_VIDEO_WAV_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_VIDEO_WAV_OPTS_SHORT[$i]}, ${_FFMPEG_VIDEO_WAV_OPTS_LONG[$i]}${_FFMPEG_VIDEO_WAV_OPTS_ARG[$i]:+ ${_FFMPEG_VIDEO_WAV_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_FFMPEG_VIDEO_WAV_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] FILE [FILE...]
Extract audio from video as 16-bit PCM WAV. Default rate 16000 Hz (Whisper-compatible).

Supported extensions: ${_FFMPEG_VIDEO_EXTS[*]}

Options:
$usage_opts
Examples:
	$fn video.mkv
	$fn -r 44100 *.mp4
	$fn -o audio.wav clip.mkv"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-o | --output)
			output="$2"
			shift 2
			;;
		-r | --rate)
			rate="$2"
			shift 2
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		*) break ;;
		esac
	done

	eval "$(dry_run_wrapper)"

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}
	[[ $# -eq 0 ]] && {
		echo "Error: no input file" >&2
		return 1
	}
	[[ -n "$output" && $# -gt 1 ]] && {
		echo "Error: --output requires single input" >&2
		return 1
	}

	local ret=0
	for input in "$@"; do
		[[ ! -f "$input" ]] && {
			echo "Skip: $input (not found)" >&2
			ret=1
			continue
		}
		local ext="${input##*.}"
		ext="${ext,,}"
		local valid=0
		for e in "${_FFMPEG_VIDEO_EXTS[@]}"; do [[ "$ext" == "$e" ]] && {
			valid=1
			break
		}; done
		((!valid)) && {
			echo "Skip: $input (unsupported: $ext)" >&2
			ret=1
			continue
		}

		local out="${output:-${input%.*}.wav}"
		run_cmd ffmpeg -y -i "$input" -ar "$rate" -ac 1 -c:a pcm_s16le "$out" ||
			{
				echo "Error: ffmpeg failed: $input" >&2
				ret=1
			}
	done
	return $ret
}
export -f ffmpeg.video.wav

_ffmpeg.video.wav_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_VIDEO_WAV_OPTS_SHORT[@]}" "${_FFMPEG_VIDEO_WAV_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*) mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.video.wav_complete ffmpeg.video.wav

# ── ffmpeg.video.srt option metadata ─────────────────────────────────────────
#                                            0          1          2       3
_FFMPEG_VIDEO_SRT_OPTS_SHORT=(-o -t -n -h)
_FFMPEG_VIDEO_SRT_OPTS_LONG=(--output --track --dry-run --help)
_FFMPEG_VIDEO_SRT_OPTS_ARG=("FILE" "N" "" "")
_FFMPEG_VIDEO_SRT_OPTS_DESC=(
	"Output path (single input only; default: INPUT.srt)"
	"Subtitle track index, 0-based (default: 0)"
	"Print command without executing"
	"Show help"
)

# ffmpeg.video.srt: extract subtitle track as SRT file
ffmpeg.video.srt() {
	local deps=(ffmpeg)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local output="" track="0" dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_VIDEO_SRT_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_VIDEO_SRT_OPTS_SHORT[$i]}, ${_FFMPEG_VIDEO_SRT_OPTS_LONG[$i]}${_FFMPEG_VIDEO_SRT_OPTS_ARG[$i]:+ ${_FFMPEG_VIDEO_SRT_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_FFMPEG_VIDEO_SRT_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] FILE [FILE...]
Extract subtitle track from video as SRT.

Supported extensions: ${_FFMPEG_VIDEO_EXTS[*]}

Options:
$usage_opts
Examples:
	$fn video.mkv
	$fn -t 1 multi-sub.mkv
	$fn -o eng.srt video.mkv"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-o | --output)
			output="$2"
			shift 2
			;;
		-t | --track)
			track="$2"
			shift 2
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		*) break ;;
		esac
	done

	eval "$(dry_run_wrapper)"

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}
	[[ $# -eq 0 ]] && {
		echo "Error: no input file" >&2
		return 1
	}
	[[ -n "$output" && $# -gt 1 ]] && {
		echo "Error: --output requires single input" >&2
		return 1
	}

	local ret=0
	for input in "$@"; do
		[[ ! -f "$input" ]] && {
			echo "Skip: $input (not found)" >&2
			ret=1
			continue
		}
		local ext="${input##*.}"
		ext="${ext,,}"
		local valid=0
		for e in "${_FFMPEG_VIDEO_EXTS[@]}"; do [[ "$ext" == "$e" ]] && {
			valid=1
			break
		}; done
		((!valid)) && {
			echo "Skip: $input (unsupported: $ext)" >&2
			ret=1
			continue
		}

		local out="${output:-${input%.*}.srt}"
		run_cmd ffmpeg -i "$input" -map "0:s:${track}" -c:s srt -f srt -y "$out" ||
			{
				echo "Error: ffmpeg failed: $input" >&2
				ret=1
			}
	done
	return $ret
}
export -f ffmpeg.video.srt

_ffmpeg.video.srt_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_VIDEO_SRT_OPTS_SHORT[@]}" "${_FFMPEG_VIDEO_SRT_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*) mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.video.srt_complete ffmpeg.video.srt

# ── ffmpeg.mp3.tag option metadata ───────────────────────────────────────────
#                                          0          1       2
_FFMPEG_MP3_TAG_OPTS_SHORT=(-r -n -h)
_FFMPEG_MP3_TAG_OPTS_LONG=(--regex --dry-run --help)
_FFMPEG_MP3_TAG_OPTS_ARG=("PATTERN" "" "")
_FFMPEG_MP3_TAG_OPTS_DESC=(
	"Filename regex with 3 capture groups: artist, album, title (default: '(.+) - (.+) - (.+)\\.mp3\$')"
	"Print actions without executing"
	"Show help"
)

# ffmpeg.mp3.tag: write ID3 tags (artist/album/title) extracted from filename via regex
ffmpeg.mp3.tag() {
	local deps=(ffmpeg)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local regex='(.+) - (.+) - (.+)\.mp3$' dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_MP3_TAG_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_MP3_TAG_OPTS_SHORT[$i]}, ${_FFMPEG_MP3_TAG_OPTS_LONG[$i]}${_FFMPEG_MP3_TAG_OPTS_ARG[$i]:+ ${_FFMPEG_MP3_TAG_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-40s%s\n' "$sig" "${_FFMPEG_MP3_TAG_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] FILE [FILE...]
Write ID3 artist/album/title tags from filename using regex capture groups.

Options:
$usage_opts
Examples:
	$fn *.mp3
	$fn -r '^(.+) - (.+) - (.+)\\.mp3\$' *.mp3
	$fn -n *.mp3"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-r | --regex)
			regex="$2"
			shift 2
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		*) break ;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}
	[[ $# -eq 0 ]] && {
		echo "Error: no input file" >&2
		return 1
	}

	local ret=0
	for f in "$@"; do
		[[ ! -f "$f" ]] && {
			echo "Skip: $f (not found)" >&2
			ret=1
			continue
		}
		[[ "$f" =~ $regex ]] || {
			echo "Skip: $f (no match)" >&2
			continue
		}

		local artist="${BASH_REMATCH[1]}"
		local album="${BASH_REMATCH[2]}"
		local title="${BASH_REMATCH[3]}"

		if ((dryrun)); then
			echo "DRY-RUN: tag $f -> artist='$artist' album='$album' title='$title'"
		else
			local dir
			dir=$(dirname "$f")
			local base
			base=$(basename "$f")
			local tmp="$dir/._tagged_$base"
			ffmpeg -i "$f" \
				-metadata artist="$artist" \
				-metadata album="$album" \
				-metadata title="$title" \
				-codec copy -y "$tmp" 2>/dev/null &&
				mv "$tmp" "$f" ||
				{
					echo "Error: ffmpeg failed: $f" >&2
					rm -f "$tmp"
					ret=1
					continue
				}
			echo "Tagged: $f"
		fi
	done
	return $ret
}
export -f ffmpeg.mp3.tag

_ffmpeg.mp3.tag_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_MP3_TAG_OPTS_SHORT[@]}" "${_FFMPEG_MP3_TAG_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*) mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.mp3.tag_complete ffmpeg.mp3.tag

# ── ffmpeg.mp3.organize option metadata ──────────────────────────────────────
#                                              0           1       2
_FFMPEG_MP3_ORGANIZE_OPTS_SHORT=(-p -n -h)
_FFMPEG_MP3_ORGANIZE_OPTS_LONG=(--pattern --dry-run --help)
_FFMPEG_MP3_ORGANIZE_OPTS_ARG=("PATH" "" "")
_FFMPEG_MP3_ORGANIZE_OPTS_DESC=(
	"Output path pattern; variables: \${artist} \${album} \${title} (default: '\${artist}/\${album}/\${title}.mp3')"
	"Print actions without executing"
	"Show help"
)

# ffmpeg.mp3.organize: move MP3 files into folder structure based on ID3 tags
# Pattern variables: ${artist} ${album} ${title} - no eval, safe substitution
ffmpeg.mp3.organize() {
	local deps=(ffprobe)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local pattern='${artist}/${album}/${title}.mp3' dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_MP3_ORGANIZE_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_MP3_ORGANIZE_OPTS_SHORT[$i]}, ${_FFMPEG_MP3_ORGANIZE_OPTS_LONG[$i]}${_FFMPEG_MP3_ORGANIZE_OPTS_ARG[$i]:+ ${_FFMPEG_MP3_ORGANIZE_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-40s%s\n' "$sig" "${_FFMPEG_MP3_ORGANIZE_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] FILE [FILE...]
Move MP3 files into folder structure based on ID3 tags.

Options:
$usage_opts
Examples:
	$fn *.mp3
	$fn -p '\${album}/\${title}.mp3' *.mp3
	$fn -n *.mp3"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-p | --pattern)
			pattern="$2"
			shift 2
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		*) break ;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}
	[[ $# -eq 0 ]] && {
		echo "Error: no input file" >&2
		return 1
	}

	local ret=0
	for f in "$@"; do
		[[ ! -f "$f" ]] && {
			echo "Skip: $f (not found)" >&2
			ret=1
			continue
		}

		local artist
		artist=$(ffprobe -v error -show_entries format_tags=artist \
			-of default=noprint_wrappers=1:nokey=1 "$f" 2>/dev/null)
		local album
		album=$(ffprobe -v error -show_entries format_tags=album \
			-of default=noprint_wrappers=1:nokey=1 "$f" 2>/dev/null)
		local title
		title=$(ffprobe -v error -show_entries format_tags=title \
			-of default=noprint_wrappers=1:nokey=1 "$f" 2>/dev/null)

		[[ -z "$artist" || -z "$album" || -z "$title" ]] &&
			{
				echo "Skip: $f (missing tags)" >&2
				continue
			}

		# Safe pattern expansion - no eval
		local target="$pattern"
		target="${target//\$\{artist\}/$artist}"
		target="${target//\$\{album\}/$album}"
		target="${target//\$\{title\}/$title}"
		local target_dir
		target_dir=$(dirname "$target")

		if ((dryrun)); then
			echo "DRY-RUN: mv $f -> $target"
		else
			mkdir -p "$target_dir" && mv "$f" "$target" ||
				{
					echo "Error: mv failed: $f -> $target" >&2
					ret=1
					continue
				}
			echo "Moved: $f -> $target"
		fi
	done
	return $ret
}
export -f ffmpeg.mp3.organize

_ffmpeg.mp3.organize_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_MP3_ORGANIZE_OPTS_SHORT[@]}" "${_FFMPEG_MP3_ORGANIZE_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*) mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.mp3.organize_complete ffmpeg.mp3.organize

# ── ffmpeg.mp3.tag-organize option metadata ───────────────────────────────────
#                                                  0          1           2       3
_FFMPEG_MP3_TAG_ORGANIZE_OPTS_SHORT=(-r -p -n -h)
_FFMPEG_MP3_TAG_ORGANIZE_OPTS_LONG=(--regex --pattern --dry-run --help)
_FFMPEG_MP3_TAG_ORGANIZE_OPTS_ARG=("PATTERN" "PATH" "" "")
_FFMPEG_MP3_TAG_ORGANIZE_OPTS_DESC=(
	"Filename regex with 3 capture groups: artist, album, title (default: '(.+) - (.+) - (.+)\\.mp3\$')"
	"Output path pattern; variables: \${artist} \${album} \${title} (default: '\${artist}/\${album}/\${title}.mp3')"
	"Print actions without executing"
	"Show help"
)

# ffmpeg.mp3.tag-organize: extract ID3 tags from filename, write them, then organize into folders
ffmpeg.mp3.tag-organize() {
	local deps=(ffmpeg ffprobe)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local regex='(.+) - (.+) - (.+)\.mp3$'
	local pattern='${artist}/${album}/${title}.mp3'
	local dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_MP3_TAG_ORGANIZE_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_MP3_TAG_ORGANIZE_OPTS_SHORT[$i]}, ${_FFMPEG_MP3_TAG_ORGANIZE_OPTS_LONG[$i]}${_FFMPEG_MP3_TAG_ORGANIZE_OPTS_ARG[$i]:+ ${_FFMPEG_MP3_TAG_ORGANIZE_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-40s%s\n' "$sig" "${_FFMPEG_MP3_TAG_ORGANIZE_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] FILE [FILE...]
Extract artist/album/title from filename via regex, write ID3 tags, then organize into folders.

Options:
$usage_opts
Examples:
	$fn *.mp3
	$fn -r '^(.+)-(.+)-(.+)\\.mp3\$' -p '\${artist}/\${title}.mp3' *.mp3
	$fn -n *.mp3"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-r | --regex)
			regex="$2"
			shift 2
			;;
		-p | --pattern)
			pattern="$2"
			shift 2
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		*) break ;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}
	[[ $# -eq 0 ]] && {
		echo "Error: no input file" >&2
		return 1
	}

	local ret=0
	for f in "$@"; do
		[[ ! -f "$f" ]] && {
			echo "Skip: $f (not found)" >&2
			ret=1
			continue
		}
		[[ "$f" =~ $regex ]] || {
			echo "Skip: $f (no match)" >&2
			continue
		}

		local artist="${BASH_REMATCH[1]}"
		local album="${BASH_REMATCH[2]}"
		local title="${BASH_REMATCH[3]}"

		local target="$pattern"
		target="${target//\$\{artist\}/$artist}"
		target="${target//\$\{album\}/$album}"
		target="${target//\$\{title\}/$title}"
		local target_dir
		target_dir=$(dirname "$target")

		if ((dryrun)); then
			echo "DRY-RUN: $f"
			echo "  tag:  artist='$artist' album='$album' title='$title'"
			echo "  move: -> $target"
		else
			local dir
			dir=$(dirname "$f")
			local base
			base=$(basename "$f")
			local tmp="$dir/._tagged_$base"
			ffmpeg -i "$f" \
				-metadata artist="$artist" \
				-metadata album="$album" \
				-metadata title="$title" \
				-codec copy -y "$tmp" 2>/dev/null ||
				{
					echo "Error: ffmpeg failed: $f" >&2
					rm -f "$tmp"
					ret=1
					continue
				}
			mkdir -p "$target_dir" && mv "$tmp" "$target" ||
				{
					echo "Error: mv failed: $f -> $target" >&2
					rm -f "$tmp"
					ret=1
					continue
				}
			echo "Processed: $f -> $target"
		fi
	done
	return $ret
}
export -f ffmpeg.mp3.tag-organize

_ffmpeg.mp3.tag-organize_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_MP3_TAG_ORGANIZE_OPTS_SHORT[@]}" "${_FFMPEG_MP3_TAG_ORGANIZE_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*) mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.mp3.tag-organize_complete ffmpeg.mp3.tag-organize

# ═══════════════════════════════════════════════════════════════════════════════
# MKV packaging functions
# ═══════════════════════════════════════════════════════════════════════════════

# Internal helpers ─────────────────────────────────────────────────────────────

# _ffmpeg.mkv.probe_codec FILE TYPE → codec_name string
# TYPE: video | audio | subtitle
_ffmpeg.mkv.probe_codec() {
	local file="$1" type="$2"
	local stream_spec
	case "$type" in
	video)    stream_spec="v:0" ;;
	audio)    stream_spec="a:0" ;;
	subtitle) stream_spec="s:0" ;;
	*) echo "Error: unknown stream type: $type" >&2; return 1 ;;
	esac
	ffprobe -v error -select_streams "$stream_spec" \
		-show_entries stream=codec_name \
		-of default=noprint_wrappers=1:nokey=1 \
		"$file" 2>/dev/null
}

# _ffmpeg.mkv.codec_uniform TYPE FILE... → 0=all same 1=differs
_ffmpeg.mkv.codec_uniform() {
	local type="$1"; shift
	local first; first=$(_ffmpeg.mkv.probe_codec "$1" "$type")
	shift
	for f in "$@"; do
		local c; c=$(_ffmpeg.mkv.probe_codec "$f" "$type")
		[[ "$c" != "$first" ]] && return 1
	done
	return 0
}

# _ffmpeg.mkv.safe_copy CODEC TYPE → 0=safe-to-copy 1=needs-transcode
_ffmpeg.mkv.safe_copy() {
	local codec="$1" type="$2"
	local -A safe_video=([h264]=1 [hevc]=1 [vp8]=1 [vp9]=1 [av1]=1 [theora]=1)
	local -A safe_audio=([mp3]=1 [aac]=1 [flac]=1 [opus]=1 [vorbis]=1 [pcm_s16le]=1 [ac3]=1 [dts]=1)
	local -A safe_sub=([subrip]=1 [ass]=1 [srt]=1 [webvtt]=1)
	case "$type" in
	video)    [[ -n "${safe_video[$codec]:-}" ]] && return 0 ;;
	audio)    [[ -n "${safe_audio[$codec]:-}" ]] && return 0 ;;
	subtitle) [[ -n "${safe_sub[$codec]:-}" ]]   && return 0 ;;
	esac
	return 1
}

# _ffmpeg.mkv.lang_detect FILE → ISO 639-2/B code or ""
# Checks: (1) ffprobe metadata, (2) filename suffix pattern *.LANG.ext
_ffmpeg.mkv.lang_detect() {
	local file="$1"
	# (1) metadata
	local meta; meta=$(ffprobe -v error -show_entries format_tags=language \
		-of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
	[[ -n "$meta" ]] && { _ffmpeg.mkv.lang_norm "$meta"; return; }
	# (2) filename: match *.CODE.ext where CODE is 2–3 alpha chars
	local base; base=$(basename "$file")
	if [[ "$base" =~ \.([a-zA-Z]{2,3})\.[^.]+$ ]]; then
		_ffmpeg.mkv.lang_norm "${BASH_REMATCH[1]}"
		return
	fi
	echo ""
}

# _ffmpeg.mkv.lang_norm CODE → ISO 639-2/B (normalises 639-1 2-char to 3-char)
_ffmpeg.mkv.lang_norm() {
	local code="${1,,}"
	# TODO(post-MVP): full 639-1→639-2/B table; extend as needed
	local -A map=(
		[en]=eng [de]=deu [fr]=fra [es]=spa [it]=ita
		[pt]=por [ru]=rus [zh]=zho [ja]=jpn [ko]=kor
		[nl]=nld [pl]=pol [sv]=swe [ar]=ara [tr]=tur
		[cs]=ces [fi]=fin [hu]=hun [ro]=ron [da]=dan
	)
	if [[ ${#code} -eq 2 && -n "${map[$code]:-}" ]]; then
		echo "${map[$code]}"
	else
		echo "$code"
	fi
}

# _ffmpeg.mkv.parse_lang_opts LANG_STR → sets assoc array _LANG_MAP[type:index]=code
# LANG_STR format: "audio:0:eng,audio:1:jpn,sub:0:eng"
# Sets caller-scope _LANG_MAP via nameref - caller must declare -A _LANG_MAP first
_ffmpeg.mkv.parse_lang_opts() {
	local str="$1"
	local -n _map="$2"
	local entry
	IFS=',' read -ra entries <<< "$str"
	for entry in "${entries[@]}"; do
		IFS=':' read -r type idx code <<< "$entry"
		_map["${type}:${idx}"]=$(	_ffmpeg.mkv.lang_norm "$code")
	done
}

# ── ffmpeg.mkv.merge option metadata ─────────────────────────────────────────
#                                              0          1          2           3          4          5
_FFMPEG_MKV_MERGE_OPTS_SHORT=(               -o         -C         -l         -vc        -ac        -n         -h)
_FFMPEG_MKV_MERGE_OPTS_LONG=(           --output     --cover     --lang   --vcodec   --acodec   --dry-run   --help)
_FFMPEG_MKV_MERGE_OPTS_ARG=(             "FILE"      "IMG"   "TYPE:N:LANG"  "CODEC"    "CODEC"      ""        "")
_FFMPEG_MKV_MERGE_OPTS_DESC=(
	"Output MKV path (required)"
	"Image file to embed as cover art attachment"
	"Language tag override: TYPE:N:LANG[,...] e.g. audio:0:eng,sub:1:jpn"
	"Video codec for unsafe-to-copy streams (default: libx264)"
	"Audio codec for unsafe-to-copy streams (default: libopus)"
	"Print command without executing"
	"Show help"
)

# ffmpeg.mkv.merge: combine multiple files into a single MKV (parallel tracks).
# Videos → video tracks, audio → audio tracks, subtitles → subtitle tracks.
# Images must be passed via --cover (never auto-inferred).
# Codecs: copy if MKV-safe, else transcode to fallback. Override with --vcodec/--acodec.
#
# TODO(post-MVP): --name-from FIELD: derive output filename from primary video metadata tag
# TODO(post-MVP): multiple --cover files (front/back/etc with mime-type annotation)
# TODO(post-MVP): chapter file (.xml/.txt) as input type
ffmpeg.mkv.merge() {
	local deps=(ffmpeg ffprobe)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local output="" cover="" lang_str="" vcodec_override="" acodec_override="" dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_MKV_MERGE_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_MKV_MERGE_OPTS_SHORT[$i]}, ${_FFMPEG_MKV_MERGE_OPTS_LONG[$i]}${_FFMPEG_MKV_MERGE_OPTS_ARG[$i]:+ ${_FFMPEG_MKV_MERGE_OPTS_ARG[$i]}}"
		local line; printf -v line '\t%-36s%s\n' "$sig" "${_FFMPEG_MKV_MERGE_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn -o OUT [OPTIONS] FILE [FILE...]
Combine files into one MKV with parallel tracks. Inputs: video, audio, subtitle files.
Images only via --cover. Plain file paths only (caller handles URI decoding).

Options:
$usage_opts
Examples:
	$fn -o out.mkv video.mp4 eng.mp3 jpn.mp3 en.srt
	$fn -o out.mkv video.mp4 --cover poster.jpg --lang audio:0:eng,audio:1:jpn
	$fn -o out.mkv video.mp4 --vcodec libx265 --acodec flac audio.flac"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)    showhelp=1; shift ;;
		-o | --output)  output="$2"; shift 2 ;;
		-C | --cover)   cover="$2"; shift 2 ;;
		-l | --lang)    lang_str="$2"; shift 2 ;;
		-vc | --vcodec) vcodec_override="$2"; shift 2 ;;
		-ac | --acodec) acodec_override="$2"; shift 2 ;;
		-n | --dry-run) dryrun=1; shift ;;
		*) break ;;
		esac
	done

	eval "$(dry_run_wrapper)"

	((showhelp)) && { printf '%s\n' "$usage"; return 0; }
	[[ -z "$output" ]] && { echo "Error: -o/--output required" >&2; return 1; }
	[[ $# -eq 0 ]] && { echo "Error: no input files" >&2; return 1; }

	# Validate: reject file:// URIs (Nautilus glue must decode upstream)
	for f in "$@" ${cover:+"$cover"}; do
		[[ "$f" == file://* ]] && { echo "Error: URI passed as input; decode to path first: $f" >&2; return 1; }
		[[ ! -f "$f" ]] && { echo "Error: not found: $f" >&2; return 1; }
	done

	# Parse --lang overrides
	declare -A _lang_map=()
	[[ -n "$lang_str" ]] && _ffmpeg.mkv.parse_lang_opts "$lang_str" _lang_map

	# Classify inputs by extension / stream presence
	local -a video_files=() audio_files=() sub_files=()
	local -A _ext_type=([mp4]=video [mkv]=video [avi]=video [mov]=video [flv]=video
	                    [wmv]=video [webm]=video [m4v]=video [mpg]=video [mpeg]=video
	                    [mp3]=audio [aac]=audio [flac]=audio [opus]=audio [ogg]=audio
	                    [wav]=audio [m4a]=audio
	                    [srt]=subtitle [ass]=subtitle [ssa]=subtitle [vtt]=subtitle)

	for f in "$@"; do
		local ext="${f##*.}"; ext="${ext,,}"
		local ftype="${_ext_type[$ext]:-}"
		case "$ftype" in
		video)    video_files+=("$f") ;;
		audio)    audio_files+=("$f") ;;
		subtitle) sub_files+=("$f") ;;
		*)
			echo "Error: unsupported file type: $f (ext: $ext)" >&2
			echo "       Images must be passed via --cover, not as positional args." >&2
			return 1
			;;
		esac
	done

	# Build ffmpeg input args and stream mappings
	local -a ff_inputs=() ff_maps=() ff_meta=()
	local idx=0 vid_stream=0 aud_stream=0 sub_stream=0

	for f in "${video_files[@]}"; do
		ff_inputs+=(-i "$f")
		ff_maps+=(-map "$idx:v:0")
		local codec; codec=$(_ffmpeg.mkv.probe_codec "$f" video)
		local vcodec="copy"
		if ! _ffmpeg.mkv.safe_copy "$codec" video; then
			vcodec="${vcodec_override:-libx264}"
			echo "Info: $f video codec '$codec' unsafe for MKV copy → transcoding to $vcodec" >&2
		fi
		ff_meta+=(-c:v:${vid_stream} "$vcodec")
		((vid_stream++)); ((idx++))
	done

	for f in "${audio_files[@]}"; do
		ff_inputs+=(-i "$f")
		ff_maps+=(-map "$idx:a:0")
		local codec; codec=$(_ffmpeg.mkv.probe_codec "$f" audio)
		local acodec="copy"
		if ! _ffmpeg.mkv.safe_copy "$codec" audio; then
			acodec="${acodec_override:-libopus}"
			echo "Info: $f audio codec '$codec' unsafe for MKV copy → transcoding to $acodec" >&2
		fi
		ff_meta+=(-c:a:${aud_stream} "$acodec")
		# Language tag: --lang override → auto-detect → omit
		local lang="${_lang_map[audio:${aud_stream}]:-}"
		[[ -z "$lang" ]] && lang=$(_ffmpeg.mkv.lang_detect "$f")
		[[ -n "$lang" ]] && ff_meta+=(-metadata:s:a:${aud_stream} "language=$lang")
		((aud_stream++)); ((idx++))
	done

	for f in "${sub_files[@]}"; do
		ff_inputs+=(-i "$f")
		ff_maps+=(-map "$idx:0")
		local codec; codec=$(_ffmpeg.mkv.probe_codec "$f" subtitle)
		local scodec="copy"
		if ! _ffmpeg.mkv.safe_copy "$codec" subtitle; then
			scodec="ass"
			echo "Info: $f subtitle codec '$codec' unsafe for MKV copy → converting to ass" >&2
		fi
		ff_meta+=(-c:s:${sub_stream} "$scodec")
		local lang="${_lang_map[sub:${sub_stream}]:-}"
		[[ -z "$lang" ]] && lang=$(_ffmpeg.mkv.lang_detect "$f")
		[[ -n "$lang" ]] && ff_meta+=(-metadata:s:s:${sub_stream} "language=$lang")
		((sub_stream++)); ((idx++))
	done

	# Cover art as MKV attachment
	local -a ff_cover=()
	if [[ -n "$cover" ]]; then
		ff_cover=(--attach "$cover" -metadata:s:t mimetype="image/${cover##*.}")
	fi

	run_cmd ffmpeg \
		"${ff_inputs[@]}" \
		"${ff_maps[@]}" \
		"${ff_meta[@]}" \
		"${ff_cover[@]}" \
		-y "$output"
}
export -f ffmpeg.mkv.merge

_ffmpeg.mkv.merge_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_MKV_MERGE_OPTS_SHORT[@]}" "${_FFMPEG_MKV_MERGE_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*)  mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.mkv.merge_complete ffmpeg.mkv.merge

# ── ffmpeg.mkv.stitch option metadata ────────────────────────────────────────
#                                               0          1          2       3
_FFMPEG_MKV_STITCH_OPTS_SHORT=(               -o        -vc        -ac      -n         -h)
_FFMPEG_MKV_STITCH_OPTS_LONG=(           --output   --vcodec   --acodec  --dry-run  --help)
_FFMPEG_MKV_STITCH_OPTS_ARG=(             "FILE"     "CODEC"    "CODEC"     ""        "")
_FFMPEG_MKV_STITCH_OPTS_DESC=(
	"Output MKV path (required)"
	"Force video codec; default: copy if uniform across inputs, else libx264"
	"Force audio codec; default: copy if uniform across inputs, else libopus"
	"Print command without executing"
	"Show help"
)

# ffmpeg.mkv.stitch: concatenate N video files sequentially into one MKV.
# Uses concat demuxer (stream copy) when all inputs share codec/resolution/fps/samplerate.
# Falls back to concat filter + re-encode when inputs differ.
#
# TODO(post-MVP): --fps TARGET: force output framerate before concat (useful for mixed 24/30fps)
# TODO(post-MVP): --resolution WxH: scale all inputs to common resolution before concat
# TODO(post-MVP): chapter markers at each input file boundary (auto from filenames)
ffmpeg.mkv.stitch() {
	local deps=(ffmpeg ffprobe mktemp)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local output="" vcodec_override="" acodec_override="" dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_MKV_STITCH_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_MKV_STITCH_OPTS_SHORT[$i]}, ${_FFMPEG_MKV_STITCH_OPTS_LONG[$i]}${_FFMPEG_MKV_STITCH_OPTS_ARG[$i]:+ ${_FFMPEG_MKV_STITCH_OPTS_ARG[$i]}}"
		local line; printf -v line '\t%-32s%s\n' "$sig" "${_FFMPEG_MKV_STITCH_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn -o OUT [OPTIONS] FILE [FILE...]
Concatenate video files sequentially into one MKV.
Uses stream copy when inputs are uniform; re-encodes on mismatch.

Options:
$usage_opts
Examples:
	$fn -o out.mkv part1.mp4 part2.mp4 part3.mp4
	$fn -o out.mkv --vcodec libx265 clip1.mkv clip2.avi"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)    showhelp=1; shift ;;
		-o | --output)  output="$2"; shift 2 ;;
		-vc | --vcodec) vcodec_override="$2"; shift 2 ;;
		-ac | --acodec) acodec_override="$2"; shift 2 ;;
		-n | --dry-run) dryrun=1; shift ;;
		*) break ;;
		esac
	done

	eval "$(dry_run_wrapper)"

	((showhelp)) && { printf '%s\n' "$usage"; return 0; }
	[[ -z "$output" ]] && { echo "Error: -o/--output required" >&2; return 1; }
	[[ $# -lt 2 ]] && { echo "Error: at least 2 input files required" >&2; return 1; }

	for f in "$@"; do
		[[ "$f" == file://* ]] && { echo "Error: URI passed as input; decode to path first: $f" >&2; return 1; }
		[[ ! -f "$f" ]] && { echo "Error: not found: $f" >&2; return 1; }
	done

	# Determine whether stream copy is safe: all inputs must share codec, resolution, fps, samplerate
	local use_copy=1
	if [[ -n "$vcodec_override" || -n "$acodec_override" ]]; then
		use_copy=0
	else
		_ffmpeg.mkv.codec_uniform video "$@" || { use_copy=0; echo "Info: video codecs differ → re-encoding" >&2; }
		_ffmpeg.mkv.codec_uniform audio "$@" || { use_copy=0; echo "Info: audio codecs differ → re-encoding" >&2; }
	fi

	local vcodec="${vcodec_override:-libx264}"
	local acodec="${acodec_override:-libopus}"

	if ((use_copy)); then
		# Concat demuxer: write temp file list
		local tmplist; tmplist=$(mktemp /tmp/ffmpeg_stitch_XXXXXX.txt)
		for f in "$@"; do printf "file '%s'\n" "$f" >> "$tmplist"; done
		run_cmd ffmpeg -f concat -safe 0 -i "$tmplist" -c copy -y "$output"
		local ret=$?
		rm -f "$tmplist"
		return $ret
	else
		# Concat filter: build input list and filtergraph
		local -a ff_inputs=()
		local n=$# filter_v="" filter_a="" k=0
		for f in "$@"; do
			ff_inputs+=(-i "$f")
			filter_v+="[${k}:v:0]"
			filter_a+="[${k}:a:0]"
			((k++))
		done
		local filtergraph="${filter_v}${filter_a}concat=n=${n}:v=1:a=1[outv][outa]"
		run_cmd ffmpeg \
			"${ff_inputs[@]}" \
			-filter_complex "$filtergraph" \
			-map "[outv]" -map "[outa]" \
			-c:v "$vcodec" -c:a "$acodec" \
			-y "$output"
	fi
}
export -f ffmpeg.mkv.stitch

_ffmpeg.mkv.stitch_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_MKV_STITCH_OPTS_SHORT[@]}" "${_FFMPEG_MKV_STITCH_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*)  mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.mkv.stitch_complete ffmpeg.mkv.stitch

# ── ffmpeg.mkv.group option metadata ─────────────────────────────────────────
#                                               0          1        2           3           4        5          6
_FFMPEG_MKV_GROUP_OPTS_SHORT=(                -o         -P        -s          -f          -R       -l         -n         -h)
_FFMPEG_MKV_GROUP_OPTS_LONG=(            --output    --prefix    --sep    --fields   --group-regex  --lang  --dry-run  --help)
_FFMPEG_MKV_GROUP_OPTS_ARG=(              "DIR"       "STR"      "CHAR"    "N"         "PAT"    "TYPE:N:LANG"  ""       "")
_FFMPEG_MKV_GROUP_OPTS_DESC=(
	"Output directory (required)"
	"Explicit prefix string to match against all filenames"
	"Field separator character for prefix splitting (use with --fields)"
	"Number of leading fields to use as prefix (use with --sep)"
	"Regex with one capture group defining the prefix"
	"Language tag override applied to all groups: TYPE:N:LANG[,...]"
	"Print actions without executing"
	"Show help"
)

# ffmpeg.mkv.group: batch-merge files into multiple MKVs grouped by filename prefix.
# Exactly one of --prefix / (--sep + --fields) / --group-regex is required.
# A group with only one file (no peers) → warns, skips, exit code 1.
# Output filename per group = PREFIX.mkv inside output DIR.
# Collision with existing file → warns, skips group, exit code 1.
#
# TODO(post-MVP): --stitch flag: stitch same-type tracks sequentially instead of merge
# TODO(post-MVP): --name-from metadata TAG: rename output from primary video tag
# TODO(post-MVP): parallel group processing (background jobs with wait)
ffmpeg.mkv.group() {
	local deps=(ffmpeg ffprobe)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local outdir="" prefix_str="" sep="" fields="" group_regex="" lang_str="" dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_MKV_GROUP_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_MKV_GROUP_OPTS_SHORT[$i]}, ${_FFMPEG_MKV_GROUP_OPTS_LONG[$i]}${_FFMPEG_MKV_GROUP_OPTS_ARG[$i]:+ ${_FFMPEG_MKV_GROUP_OPTS_ARG[$i]}}"
		local line; printf -v line '\t%-40s%s\n' "$sig" "${_FFMPEG_MKV_GROUP_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn -o DIR (--prefix STR | --sep C --fields N | --group-regex PAT) FILE [FILE...]
Batch-merge files into multiple MKVs, grouped by filename prefix.
Exactly one grouping strategy required. Lone files (no peers) are skipped.

Options:
$usage_opts
Examples:
	$fn -o out/ --sep . --fields 3 Series.S01E01.en.srt Series.S01E01.mp4 Series.S01E02.mp4
	$fn -o out/ --group-regex '(.+\.[Ss][0-9]+[Ee][0-9]+)' *.mp4 *.srt *.mp3
	$fn -o out/ --prefix 'Series.S01E01' Series.S01E01.mp4 Series.S01E01.en.srt"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)        showhelp=1; shift ;;
		-o | --output)      outdir="$2"; shift 2 ;;
		-P | --prefix)      prefix_str="$2"; shift 2 ;;
		-s | --sep)         sep="$2"; shift 2 ;;
		-f | --fields)      fields="$2"; shift 2 ;;
		-R | --group-regex) group_regex="$2"; shift 2 ;;
		-l | --lang)        lang_str="$2"; shift 2 ;;
		-n | --dry-run)     dryrun=1; shift ;;
		*) break ;;
		esac
	done

	((showhelp)) && { printf '%s\n' "$usage"; return 0; }
	[[ -z "$outdir" ]] && { echo "Error: -o/--output required" >&2; return 1; }
	[[ $# -eq 0 ]] && { echo "Error: no input files" >&2; return 1; }

	# Validate exactly one grouping strategy
	local strategy_count=0
	[[ -n "$prefix_str" ]] && ((strategy_count++))
	[[ -n "$sep" || -n "$fields" ]] && ((strategy_count++))
	[[ -n "$group_regex" ]] && ((strategy_count++))
	[[ $strategy_count -ne 1 ]] && {
		echo "Error: exactly one of --prefix, (--sep + --fields), --group-regex required" >&2
		return 1
	}
	[[ -n "$sep" && -z "$fields" ]] && { echo "Error: --sep requires --fields" >&2; return 1; }
	[[ -n "$fields" && -z "$sep" ]] && { echo "Error: --fields requires --sep" >&2; return 1; }

	for f in "$@"; do
		[[ "$f" == file://* ]] && { echo "Error: URI passed; decode to path first: $f" >&2; return 1; }
		[[ ! -f "$f" ]] && { echo "Error: not found: $f" >&2; return 1; }
	done

	# Build prefix→files map
	declare -A _groups=()
	for f in "$@"; do
		local base; base=$(basename "$f")
		local pfx=""

		if [[ -n "$prefix_str" ]]; then
			[[ "$base" == "${prefix_str}"* ]] && pfx="$prefix_str"
		elif [[ -n "$sep" ]]; then
			pfx=$(echo "$base" | cut -d"$sep" -f"1-${fields}")
		elif [[ -n "$group_regex" ]]; then
			if [[ "$base" =~ $group_regex ]]; then
				pfx="${BASH_REMATCH[1]}"
			fi
		fi

		if [[ -z "$pfx" ]]; then
			echo "Warning: no prefix match for $f - skipping" >&2
			continue
		fi
		_groups["$pfx"]+="$f"$'\n'
	done

	[[ ${#_groups[@]} -eq 0 ]] && { echo "Error: no groups formed" >&2; return 1; }

	local ret=0
	for pfx in "${!_groups[@]}"; do
		# Split newline-separated file list back into array
		local -a grp_files=()
		while IFS= read -r line; do
			[[ -n "$line" ]] && grp_files+=("$line")
		done <<< "${_groups[$pfx]}"

		# Lone file - no peers
		if [[ ${#grp_files[@]} -eq 1 ]]; then
			echo "Warning: group '$pfx' has only one file (${grp_files[0]}) - skipping" >&2
			ret=1
			continue
		fi

		local out_file="$outdir/${pfx}.mkv"
		if [[ -f "$out_file" ]]; then
			echo "Warning: output exists: $out_file - skipping group '$pfx'" >&2
			ret=1
			continue
		fi

		mkdir -p "$outdir"

		local merge_args=(-o "$out_file")
		[[ -n "$lang_str" ]] && merge_args+=(--lang "$lang_str")
		((dryrun)) && merge_args+=(-n)

		ffmpeg.mkv.merge "${merge_args[@]}" "${grp_files[@]}" || {
			echo "Error: merge failed for group '$pfx'" >&2
			ret=1
		}
	done
	return $ret
}
export -f ffmpeg.mkv.group

_ffmpeg.mkv.group_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_MKV_GROUP_OPTS_SHORT[@]}" "${_FFMPEG_MKV_GROUP_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*)  mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.mkv.group_complete ffmpeg.mkv.group

# ── ffmpeg.mkv.seq option metadata ───────────────────────────────────────────
#                                             0          1          2           3       4
_FFMPEG_MKV_SEQ_OPTS_SHORT=(                -o         -r         -p          -s      -n         -h)
_FFMPEG_MKV_SEQ_OPTS_LONG=(            --output      --rate   --pattern     --sort  --dry-run  --help)
_FFMPEG_MKV_SEQ_OPTS_ARG=(              "FILE"        "FPS"    "GLOB"    "name|mtime"  ""       "")
_FFMPEG_MKV_SEQ_OPTS_DESC=(
	"Output MKV path (required)"
	"Frames per second (default: 24)"
	"Glob pattern for image files (alternative to FILE... list)"
	"Sort order for input frames: name (default) or mtime"
	"Print command without executing"
	"Show help"
)

# ffmpeg.mkv.seq: encode an image sequence into an MKV video track.
# Accepts explicit FILE... list or --pattern GLOB. Sorts by name or mtime.
# Nautilus/KDE passes files in arbitrary order - always sort before encoding.
#
# TODO(post-MVP): --audio FILE: attach audio track to output MKV (calls ffmpeg.mkv.merge)
# TODO(post-MVP): --loop N: repeat sequence N times
# TODO(post-MVP): --transition fade|cut: crossfade between frames
ffmpeg.mkv.seq() {
	local deps=(ffmpeg mktemp)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local output="" rate="24" pattern="" sort_by="name" dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_MKV_SEQ_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_MKV_SEQ_OPTS_SHORT[$i]}, ${_FFMPEG_MKV_SEQ_OPTS_LONG[$i]}${_FFMPEG_MKV_SEQ_OPTS_ARG[$i]:+ ${_FFMPEG_MKV_SEQ_OPTS_ARG[$i]}}"
		local line; printf -v line '\t%-32s%s\n' "$sig" "${_FFMPEG_MKV_SEQ_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn -o OUT [OPTIONS] [FILE...]
Encode image sequence to MKV. Pass files explicitly or via --pattern GLOB.
Files are always sorted before encoding (Nautilus-safe).

Supported image types: jpg jpeg png webp bmp tiff gif

Options:
$usage_opts
Examples:
	$fn -o timelapse.mkv -r 30 frame*.jpg
	$fn -o out.mkv --pattern 'screenshots/*.png' --sort mtime
	$fn -o slide.mkv -r 1 slide01.png slide02.png slide03.png"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)    showhelp=1; shift ;;
		-o | --output)  output="$2"; shift 2 ;;
		-r | --rate)    rate="$2"; shift 2 ;;
		-p | --pattern) pattern="$2"; shift 2 ;;
		-s | --sort)    sort_by="$2"; shift 2 ;;
		-n | --dry-run) dryrun=1; shift ;;
		*) break ;;
		esac
	done

	eval "$(dry_run_wrapper)"

	((showhelp)) && { printf '%s\n' "$usage"; return 0; }
	[[ -z "$output" ]] && { echo "Error: -o/--output required" >&2; return 1; }

	local -a img_exts=(jpg jpeg png webp bmp tiff tif gif)

	# Collect files from --pattern or positional args
	local -a raw_files=()
	if [[ -n "$pattern" ]]; then
		# glob expansion in current shell - safe, no eval
		local -a globbed=($pattern)
		[[ ${#globbed[@]} -eq 0 || ! -f "${globbed[0]}" ]] && \
			{ echo "Error: --pattern matched no files: $pattern" >&2; return 1; }
		raw_files=("${globbed[@]}")
	elif [[ $# -gt 0 ]]; then
		raw_files=("$@")
	else
		echo "Error: no input files and no --pattern given" >&2
		return 1
	fi

	# Validate all inputs are images
	for f in "${raw_files[@]}"; do
		[[ "$f" == file://* ]] && { echo "Error: URI passed; decode to path first: $f" >&2; return 1; }
		[[ ! -f "$f" ]] && { echo "Error: not found: $f" >&2; return 1; }
		local ext="${f##*.}"; ext="${ext,,}"
		local valid=0
		for e in "${img_exts[@]}"; do [[ "$ext" == "$e" ]] && { valid=1; break; }; done
		(( !valid )) && { echo "Error: not a supported image: $f (ext: $ext)" >&2; return 1; }
	done

	# Sort
	local -a sorted_files=()
	if [[ "$sort_by" == "mtime" ]]; then
		mapfile -t sorted_files < <(ls -t "${raw_files[@]}" 2>/dev/null)
	else
		mapfile -t sorted_files < <(printf '%s\n' "${raw_files[@]}" | sort)
	fi

	# Write concat demuxer file list (one frame = one image, duration = 1/fps)
	local tmplist; tmplist=$(mktemp /tmp/ffmpeg_seq_XXXXXX.txt)
	local frame_duration; frame_duration=$(awk -v r="$rate" 'BEGIN { printf "%.6g", 1/r }')
	for f in "${sorted_files[@]}"; do
		printf "file '%s'\nduration %s\n" "$f" "$frame_duration" >> "$tmplist"
	done
	# Repeat last frame to avoid last-frame truncation (ffmpeg concat demuxer quirk)
	printf "file '%s'\n" "${sorted_files[-1]}" >> "$tmplist"

	run_cmd ffmpeg -f concat -safe 0 -i "$tmplist" \
		-c:v libx264 -pix_fmt yuv420p \
		-vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" \
		-y "$output"
	local ret=$?
	rm -f "$tmplist"
	return $ret
}
export -f ffmpeg.mkv.seq

_ffmpeg.mkv.seq_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_MKV_SEQ_OPTS_SHORT[@]}" "${_FFMPEG_MKV_SEQ_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*)  mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.mkv.seq_complete ffmpeg.mkv.seq

# ── ffmpeg.video.compress option metadata ─────────────────────────────────────
# Compression level → libx265 CRF + ffmpeg preset mapping:
#   low    → crf 24, preset medium  (near-lossless, ~40% smaller)
#   medium → crf 28, preset medium  (default, good quality/size balance)
#   high   → crf 35, preset slow    (visible loss, very small files)
#   max    → crf 42, preset veryslow(aggressive; use for archival space savings)
# CRF scale: lower = better quality, larger file. libx265 range: 0–51.
#                                                0          1         2          3       4
_FFMPEG_VIDEO_COMPRESS_OPTS_SHORT=(             -o         -l        -c         -n      -h)
_FFMPEG_VIDEO_COMPRESS_OPTS_LONG=(         --output    --level     --crf    --dry-run  --help)
_FFMPEG_VIDEO_COMPRESS_OPTS_ARG=(           "FILE"  "low|medium|high|max"  "N"   ""    "")
_FFMPEG_VIDEO_COMPRESS_OPTS_DESC=(
	"Output path (single input only; default: INPUT.cmp.mkv)"
	"Compression level: low medium high max (default: medium)"
	"Raw CRF value 0–51; overrides --level"
	"Print command without executing"
	"Show help"
)

# ffmpeg.video.compress: re-encode video with libx265 at given compression level.
# Output is always MKV. Audio is copied if MKV-safe, else transcoded to libopus.
#
# TODO(post-MVP): --vcodec override (av1/libx264) for broader device compatibility
# TODO(post-MVP): --target-size MB: binary-search CRF to hit target file size
ffmpeg.video.compress() {
	local deps=(ffmpeg ffprobe)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local output="" level="medium" crf_override="" dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_VIDEO_COMPRESS_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_VIDEO_COMPRESS_OPTS_SHORT[$i]}, ${_FFMPEG_VIDEO_COMPRESS_OPTS_LONG[$i]}${_FFMPEG_VIDEO_COMPRESS_OPTS_ARG[$i]:+ ${_FFMPEG_VIDEO_COMPRESS_OPTS_ARG[$i]}}"
		local line; printf -v line '\t%-36s%s\n' "$sig" "${_FFMPEG_VIDEO_COMPRESS_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] FILE [FILE...]
Re-encode video(s) with libx265. Output: INPUT.cmp.mkv.
Audio is stream-copied if MKV-safe, else transcoded to libopus.

Levels:  low (crf 24)  medium (crf 28)  high (crf 35)  max (crf 42)

Options:
$usage_opts
Examples:
	$fn video.mp4
	$fn -l high *.mkv
	$fn --crf 30 -o out.mkv video.mov"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)    showhelp=1; shift ;;
		-o | --output)  output="$2"; shift 2 ;;
		-l | --level)   level="$2"; shift 2 ;;
		-c | --crf)     crf_override="$2"; shift 2 ;;
		-n | --dry-run) dryrun=1; shift ;;
		*) break ;;
		esac
	done

	eval "$(dry_run_wrapper)"

	((showhelp)) && { printf '%s\n' "$usage"; return 0; }
	[[ $# -eq 0 ]] && { echo "Error: no input file" >&2; return 1; }
	[[ -n "$output" && $# -gt 1 ]] && { echo "Error: --output requires single input" >&2; return 1; }

	# Resolve CRF + ffmpeg preset from level (overridden by --crf if given)
	local crf preset
	case "$level" in
	low)    crf=24; preset="medium" ;;
	medium) crf=28; preset="medium" ;;
	high)   crf=35; preset="slow"   ;;
	max)    crf=42; preset="veryslow" ;;
	*)      echo "Error: unknown level '$level'; use low|medium|high|max" >&2; return 1 ;;
	esac
	[[ -n "$crf_override" ]] && crf="$crf_override"

	local ret=0
	for input in "$@"; do
		[[ "$input" == file://* ]] && { echo "Error: URI passed; decode to path first: $input" >&2; ret=1; continue; }
		[[ ! -f "$input" ]] && { echo "Skip: $input (not found)" >&2; ret=1; continue; }
		local ext="${input##*.}"; ext="${ext,,}"
		local valid=0
		for e in "${_FFMPEG_VIDEO_EXTS[@]}"; do [[ "$ext" == "$e" ]] && { valid=1; break; }; done
		(( !valid )) && { echo "Skip: $input (unsupported: $ext)" >&2; ret=1; continue; }

		local out="${output:-${input%.*}.cmp.mkv}"

		# Audio: copy if MKV-safe, else libopus
		local acodec="copy"
		local acodec_detected; acodec_detected=$(_ffmpeg.mkv.probe_codec "$input" audio)
		if [[ -n "$acodec_detected" ]] && ! _ffmpeg.mkv.safe_copy "$acodec_detected" audio; then
			acodec="libopus"
			echo "Info: audio codec '$acodec_detected' unsafe for MKV copy → transcoding to libopus" >&2
		fi

		run_cmd ffmpeg -i "$input" \
			-c:v libx265 -crf "$crf" -preset "$preset" \
			-c:a "$acodec" \
			-y "$out" || { echo "Error: ffmpeg failed: $input" >&2; ret=1; }
	done
	return $ret
}
export -f ffmpeg.video.compress

_ffmpeg.video.compress_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_VIDEO_COMPRESS_OPTS_SHORT[@]}" "${_FFMPEG_VIDEO_COMPRESS_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*)  mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.video.compress_complete ffmpeg.video.compress

# ── ffmpeg.video.scenes option metadata ───────────────────────────────────────
# ffmpeg select=gt(scene,T) computes inter-frame difference score 0–1.
# Frame is kept when score > T. Lower T = more frames, higher = fewer.
# 0.2: catches most cuts + dissolves, ~1 keyframe per camera change.
#                                                 0             1          2       3
_FFMPEG_VIDEO_SCENES_OPTS_SHORT=(               -o            -t         -n      -h)
_FFMPEG_VIDEO_SCENES_OPTS_LONG=(           --output    --threshold   --dry-run  --help)
_FFMPEG_VIDEO_SCENES_OPTS_ARG=(           "PATTERN"        "0.N"        ""      "")
_FFMPEG_VIDEO_SCENES_OPTS_DESC=(
	"Output filename pattern (single input only; default: INPUT_scene_%03d.png)"
	"Scene-change detection threshold 0.0–1.0 (default: 0.2)"
	"Print command without executing"
	"Show help"
)

# ffmpeg.video.scenes: extract key stillframes at scene-change boundaries.
# Uses ffmpeg's scene-change detection (select filter) + variable frame rate.
ffmpeg.video.scenes() {
	local deps=(ffmpeg)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local output="" threshold="0.2" dryrun=0 showhelp=0

	local usage_opts="" i
	for ((i = 0; i < ${#_FFMPEG_VIDEO_SCENES_OPTS_SHORT[@]}; i++)); do
		local sig="${_FFMPEG_VIDEO_SCENES_OPTS_SHORT[$i]}, ${_FFMPEG_VIDEO_SCENES_OPTS_LONG[$i]}${_FFMPEG_VIDEO_SCENES_OPTS_ARG[$i]:+ ${_FFMPEG_VIDEO_SCENES_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-36s%s\n' "$sig" "${_FFMPEG_VIDEO_SCENES_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] FILE [FILE...]
Extract key stillframes at scene-change boundaries as PNG images.

Supported extensions: ${_FFMPEG_VIDEO_EXTS[*]}

Options:
$usage_opts
Examples:
	$fn video.mp4
	$fn -t 0.4 movie.mkv
	$fn -o 'frames/scene_%04d.png' clip.mp4"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)       showhelp=1; shift ;;
		-o | --output)     output="$2"; shift 2 ;;
		-t | --threshold)  threshold="$2"; shift 2 ;;
		-n | --dry-run)    dryrun=1; shift ;;
		*) break ;;
		esac
	done

	eval "$(dry_run_wrapper)"

	((showhelp)) && { printf '%s\n' "$usage"; return 0; }
	[[ $# -eq 0 ]] && { echo "Error: no input file" >&2; return 1; }
	[[ -n "$output" && $# -gt 1 ]] && { echo "Error: --output requires single input" >&2; return 1; }

	# Validate threshold range
	if ! awk -v t="$threshold" 'BEGIN { exit (t >= 0 && t <= 1 ? 0 : 1) }'; then
		echo "Error: threshold must be 0.0–1.0, got '$threshold'" >&2
		return 1
	fi

	local ret=0
	for input in "$@"; do
		[[ "$input" == file://* ]] && { echo "Error: URI passed; decode to path first: $input" >&2; ret=1; continue; }
		[[ ! -f "$input" ]] && { echo "Skip: $input (not found)" >&2; ret=1; continue; }
		local ext="${input##*.}"; ext="${ext,,}"
		local valid=0
		for e in "${_FFMPEG_VIDEO_EXTS[@]}"; do [[ "$ext" == "$e" ]] && { valid=1; break; }; done
		(( !valid )) && { echo "Skip: $input (unsupported: $ext)" >&2; ret=1; continue; }

		local base="${input%.*}"
		local out="${output:-${base}_scene_%03d.png}"

		run_cmd ffmpeg -i "$input" \
			-vf "select='gt(scene,${threshold})'" \
			-vsync vfr \
			-y "$out" || { echo "Error: ffmpeg failed: $input" >&2; ret=1; }
	done
	return $ret
}
export -f ffmpeg.video.scenes

_ffmpeg.video.scenes_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_FFMPEG_VIDEO_SCENES_OPTS_SHORT[@]}" "${_FFMPEG_VIDEO_SCENES_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*)  mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _ffmpeg.video.scenes_complete ffmpeg.video.scenes
