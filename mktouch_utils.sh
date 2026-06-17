#!/usr/bin/env bash

# mktouch - Create directories and files with preset support
# Presets are loaded from (in order of precedence):
#   1. .mktouchrc (project-local)
#   2. ~/.config/mktouch/presets (user)
#   3. /etc/mktouch/presets (system)

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# ── mktouch config paths (cascading hierarchy) ───────────────────────────────
MKT_PRESET_PATHS=(
	"${SCRIPT_DIR}/data/mktouch/mktouch.conf"
	"/etc/mktouch/presets"
	"${HOME}/.config/mktouch/presets"
	"${HOME}/.mktouchrc"
)

# ── mktouch option metadata ───────────────────────────────────────────────────
#                                           0            1          2       3         4          5
_MKTOUCH_OPTS_SHORT=(-C -t -n -d -p -l -h)
_MKTOUCH_OPTS_LONG=(--prefix --tree --dry-run --debug --preset --list-presets --help)
_MKTOUCH_OPTS_ARG=("DIR" "" "" "" "NAME" "" "")
_MKTOUCH_OPTS_DESC=(
	"Prefix all paths (git -C style)"
	"Show tree of created paths"
	"Preview only"
	"Print debug info"
	"Use preset (explicit mode)"
	"List available presets"
	"Show this help"
)

# ── preset lookup ─────────────────────────────────────────────────────────────
# Usage: mktouch.preset.get <name>
# Returns: space-separated paths or empty if not found
mktouch.preset.get() {
	local name="$1"
	local preset_value=""

	for config_file in "${MKT_PRESET_PATHS[@]}"; do
		if [[ -f "$config_file" ]]; then
			# Format: preset_name="path1 path2 path3..."
			preset_value=$(grep -E "^${name}=" "$config_file" 2>/dev/null | cut -d'=' -f2- | sed 's/^"//;s/"$//')
			if [[ -n "$preset_value" ]]; then
				echo "$preset_value"
				return 0
			fi
		fi
	done
	return 1
}
export -f mktouch.preset.get

# ── list all available presets ────────────────────────────────────────────────
mktouch.preset.list() {
	local presets=()
	local seen=()

	for config_file in "${MKT_PRESET_PATHS[@]}"; do
		if [[ -f "$config_file" ]]; then
			while IFS= read -r line; do
				[[ "$line" =~ ^[[:space:]]*# ]] && continue
				[[ -z "$line" ]] && continue

				local pname="${line%%=*}"
				[[ -z "$pname" ]] && continue

				local already_seen=0
				for s in "${seen[@]}"; do
					[[ "$s" == "$pname" ]] && {
						already_seen=1
						break
					}
				done

				((already_seen)) || {
					seen+=("$pname")
					presets+=("$pname")
				}
			done <"$config_file"
		fi
	done

	[[ ${#presets[@]} -eq 0 ]] && {
		echo "No presets found." >&2
		return 1
	}
	printf '%s\n' "${presets[@]}" | sort
}
export -f mktouch.preset.list

# ── mktouch ───────────────────────────────────────────────────────────────────
mktouch() {
	local deps=(tree)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local paths=() created=()
	local show_tree=0 dry_run=0 list_presets=0 debug=0 showhelp=0
	local prefix=""
	local use_presets=()

	local usage_opts="" i
	for ((i = 0; i < ${#_MKTOUCH_OPTS_SHORT[@]}; i++)); do
		local sig="${_MKTOUCH_OPTS_SHORT[$i]}, ${_MKTOUCH_OPTS_LONG[$i]}${_MKTOUCH_OPTS_ARG[$i]:+ ${_MKTOUCH_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_MKTOUCH_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local fn="${FUNCNAME[0]}"
	local usage="Usage: $fn [OPTIONS] <path|preset> [<path|preset> ...]
Creates directories and files for given paths.

Options:
${usage_opts}
Presets:
	Defined in .mktouchrc, ~/.config/mktouch/presets, or /etc/mktouch/presets.
	$fn presetname       (auto-detected)
	$fn -p presetname    (explicit)"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-C | --prefix)
			prefix="$2"
			shift 2
			;;
		-t | --tree)
			show_tree=1
			shift
			;;
		-n | --dry-run)
			dry_run=1
			show_tree=1
			shift
			;;
		-d | --debug)
			debug=1
			shift
			;;
		-p | --preset)
			use_presets+=("$2")
			shift 2
			;;
		-l | --list-presets)
			list_presets=1
			shift
			;;
		--)
			shift
			break
			;;
		-*)
			echo "Error: unknown option $1" >&2
			return 1
			;;
		*)
			local preset_paths
			preset_paths=$(mktouch.preset.get "$1" 2>/dev/null)
			if [[ -n "$preset_paths" ]]; then
				read -ra expanded <<<"$preset_paths"
				paths+=("${expanded[@]}")
			else
				paths+=("$1")
			fi
			shift
			;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}

	((debug)) && {
		echo "Debug: SCRIPT_DIR=${SCRIPT_DIR}"
		echo "Debug: Config paths:"
		for p in "${MKT_PRESET_PATHS[@]}"; do
			local exists="missing"
			[[ -f "$p" ]] && exists="exists"
			echo "  [$exists] $p"
		done
		echo "Debug: paths=${paths[*]}"
		echo "Debug: prefix=${prefix}"
		echo "Debug: use_presets=${use_presets[*]}"
	}

	((list_presets)) && {
		mktouch.preset.list
		return $?
	}

	for preset_name in "${use_presets[@]}"; do
		local preset_paths
		preset_paths=$(mktouch.preset.get "$preset_name" 2>/dev/null)
		[[ -z "$preset_paths" ]] && {
			echo "Error: preset not found: $preset_name" >&2
			return 1
		}
		read -ra expanded <<<"$preset_paths"
		paths+=("${expanded[@]}")
	done

	paths+=("$@")

	[[ ${#paths[@]} -eq 0 ]] && {
		echo "Error: no paths" >&2
		return 1
	}

	[[ -n "$prefix" ]] && paths=("${paths[@]/#/$prefix/}")

	((dry_run)) && {
		printf '%s\n' "${paths[@]}" | tree --fromfile -F --noreport --dirsfirst
		return 0
	}

	for p in "${paths[@]}"; do
		if [[ "$p" == */ ]]; then
			mkdir -p "$p"
		else
			mkdir -p "$(dirname -- "$p")"
			touch "$p"
		fi
		created+=("$p")
	done

	((show_tree)) && {
		printf '%s\n' "${created[@]}" | tree --fromfile -F --noreport --dirsfirst || true
	}
}
export -f mktouch

_mktouch_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_MKTOUCH_OPTS_SHORT[@]}" "${_MKTOUCH_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*) mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _mktouch_complete mktouch
