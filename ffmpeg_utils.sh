#!/usr/bin/env bash

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

	run_cmd() {
		((dryrun)) && {
			echo "DRY-RUN: $*"
			return
		}
		"$@"
	}

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

	run_cmd() {
		((dryrun)) && {
			echo "DRY-RUN: $*"
			return
		}
		"$@"
	}

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

	run_cmd() {
		((dryrun)) && {
			echo "DRY-RUN: $*"
			return
		}
		"$@"
	}

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

	run_cmd() {
		((dryrun)) && {
			echo "DRY-RUN: $*"
			return
		}
		"$@"
	}

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
# Pattern variables: ${artist} ${album} ${title} — no eval, safe substitution
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

		# Safe pattern expansion — no eval
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
