#!/usr/bin/env bash

# mktouch - Create directories and files with preset support
# Presets are loaded from (in order of precedence):
#   1. .mktouchrc (project-local)
#   2. ~/.config/mktouch/presets (user)
#   3. /etc/mktouch/presets (system)

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# ---- config paths (cascading hierarchy) ----
MKT_PRESET_PATHS=(
	"${SCRIPT_DIR}/data/mktouch/mktouch.conf"
	"/etc/mktouch/presets"
	"${HOME}/.config/mktouch/presets"
	"${HOME}/.mktouchrc"
)

# ---- preset lookup ----
# Usage: mktouch.preset.get <name>
# Returns: space-separated paths or empty if not found
mktouch.preset.get() {
	local name="$1"
	local preset_value=""
	
	for config_file in "${MKT_PRESET_PATHS[@]}"; do
		if [[ -f "$config_file" ]]; then
			# Read preset from config file
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

# ---- list all available presets ----
mktouch.preset.list() {
	local presets=()
	local seen=()
	
	for config_file in "${MKT_PRESET_PATHS[@]}"; do
		if [[ -f "$config_file" ]]; then
			while IFS= read -r line; do
				# Skip comments and empty lines
				[[ "$line" =~ ^[[:space:]]*# ]] && continue
				[[ -z "$line" ]] && continue
				
				# Extract preset name
				local pname="${line%%=*}"
				[[ -z "$pname" ]] && continue
				
				# Check if already seen (higher precedence wins)
				local already_seen=false
				for s in "${seen[@]}"; do
					if [[ "$s" == "$pname" ]]; then
						already_seen=true
						break
					fi
				done
				
				if [[ "$already_seen" == false ]]; then
					seen+=("$pname")
					presets+=("$pname")
				fi
			done < "$config_file"
		fi
	done
	
	if [[ ${#presets[@]} -eq 0 ]]; then
		echo "No presets found." >&2
		return 1
	fi
	
	printf '%s\n' "${presets[@]}" | sort
}

# ---- main mktouch function ----
mktouch() {
	local deps=(tree)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			return 127 2>/dev/null || exit 127
		}
	done
	
	local paths=() created=()
	local show_tree=false dry_run=false list_presets=false debug=false
	local prefix=""
	local use_presets=()
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				cat <<-EOF
				Usage: ${FUNCNAME[0]} [OPTIONS] [--path|-p] <path|preset> [<path|preset> ...]
				Creates directories and files for given paths.

				Options:
					-C, --prefix <dir>     Prefix all paths (git -C style)
					-t, --tree             Show tree of created paths
					-n, --dry-run          Preview only
					-d, --debug            Print debug info
					-p, --preset <name>    Use preset (explicit mode)
					-l, --list-presets     List available presets
					-h, --help             Show this help

				Presets:
					Presets are defined in .mktouchrc, ~/.config/mktouch/presets,
					or /etc/mktouch/presets. Call with:
						mktouch presetname       (auto-detected)
						mktouch -p presetname    (explicit)
				EOF
				return 0 ;;
			-C|--prefix)
				shift; [[ $# -eq 0 ]] && { echo "Error: --prefix needs arg" >&2; return 1; }
				prefix="$1"; shift ;;
			-t|--tree) show_tree=true; shift ;;
			-n|--dry-run) dry_run=true; show_tree=true; shift ;;
			-d|--debug) debug=true; shift ;;
			-p|--preset)
				shift; [[ $# -eq 0 ]] && { echo "Error: --preset needs arg" >&2; return 1; }
				use_presets+=("$1"); shift ;;
			-l|--list-presets) list_presets=true; shift ;;
			--) shift; break ;;
			-*) echo "Error: unknown option $1" >&2; return 1 ;;
			*)
				# Check if it's a preset name
				local preset_paths
				preset_paths=$(mktouch.preset.get "$1" 2>/dev/null)
				if [[ -n "$preset_paths" ]]; then
					# It's a preset - expand it
					read -ra expanded <<< "$preset_paths"
					paths+=("${expanded[@]}")
				else
					# It's a regular path
					paths+=("$1")
				fi
				shift ;;
		esac
	done

	# Print debug info
	if [[ "$debug" == true ]]; then
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
	fi

	# Handle --list-presets
	if $list_presets; then
		mktouch.preset.list
		return $?
	fi
	
	# Handle explicit --preset(s)
	for preset_name in "${use_presets[@]}"; do
		local preset_paths
		preset_paths=$(mktouch.preset.get "$preset_name" 2>/dev/null)
		if [[ -z "$preset_paths" ]]; then
			echo "Error: preset not found: $preset_name" >&2
			return 1
		fi
		read -ra expanded <<< "$preset_paths"
		paths+=("${expanded[@]}")
	done
	
	# Add remaining args
	paths+=("$@")
	
	[[ ${#paths[@]} -eq 0 ]] && { echo "Error: no paths" >&2; return 1; }

	if [[ -n "$prefix" ]]; then
		paths=("${paths[@]/#/$prefix/}")
	fi

	if $dry_run; then
		printf '%s\n' "${paths[@]}" \
		| tree --fromfile -F --noreport --dirsfirst
		return 0
	fi

	for p in "${paths[@]}"; do
		if [[ "$p" == */ ]]; then
			mkdir -p "$p"
		else
			mkdir -p "$(dirname -- "$p")"
			touch "$p"
		fi
		created+=("$p")
	done

	if $show_tree; then
		printf '%s\n' "${created[@]}" \
		| tree --fromfile -F --noreport --dirsfirst || true
	fi
}

export -f mktouch
