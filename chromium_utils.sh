#!/usr/bin/env bash

# === Chromium Profile Management - Feature Backlog ===
# See BRD: docs/feat/chromium/0.req/BRD.md
#
# Phase 0 (Lib):           resolve profile paths & names, handle SQLite, store reusable SQL Queries as files
# Phase 1 (Foundation):    profile.ls, profile.info, profile.create, safety guards
# Phase 2 (Read/Query):    port.keywords, port.bookmarks
# Phase 3 (Write/Mutate):  profile.clone, profile.rm
# Phase 4 (Remaining):     port.extensions, port.history, port.cookies, port.prefs
# Phase 5 (Bulk + X-br):   port (dispatcher), backup/restore, cross-browser mapping
#
# Profile is directory: $CHROME_CONFIG/<Name>/
# Key sections: Preferences (JSON), Bookmarks (JSON), Web Data (SQLite),
#   History (SQLite), Cookies (SQLite), Login Data (SQLite),
#   Extensions/ (dirs), Sessions/ (binary), Local State (JSON, profile-level)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

# ── chromium.search.keywords option metadata ──────────────────────────────────
#                                                    0       1          2
_CHROMIUM_SEARCH_KEYWORDS_OPTS_SHORT=(-c -C -h)
_CHROMIUM_SEARCH_KEYWORDS_OPTS_LONG=(--csv --columns --help)
_CHROMIUM_SEARCH_KEYWORDS_OPTS_ARG=("" "COLS" "")
_CHROMIUM_SEARCH_KEYWORDS_OPTS_DESC=(
	"Print as CSV"
	"Comma-separated columns (default: short_name,keyword,url)"
	"Show help"
)

chromium.search.keywords() {
	local deps=(sqlite3)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local chromium_config="$HOME/.config/chromium"
	local db_file="Web Data"
	local profile_dir_default="Default"
	local columns_default="short_name,keyword,url"

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_SEARCH_KEYWORDS_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_SEARCH_KEYWORDS_OPTS_SHORT[$i]}, ${_CHROMIUM_SEARCH_KEYWORDS_OPTS_LONG[$i]}${_CHROMIUM_SEARCH_KEYWORDS_OPTS_ARG[$i]:+ ${_CHROMIUM_SEARCH_KEYWORDS_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_SEARCH_KEYWORDS_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local usage="Usage: $fn [OPTIONS] [PROFILE]
Query Chromium profile search engines from Web Data SQLite DB.

PROFILE: full path or name resolved inside ${chromium_config} (default: ${profile_dir_default})

Options:
$usage_opts
Examples:
	$fn Default
	$fn \"/home/user/.config/google-chrome/Profile 3\"
	$fn --csv --columns url Default"

	local showhelp=0 opt_csv=0 opt_columns=""
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-c | --csv)
			opt_csv=1
			shift
			;;
		-C | --columns)
			opt_columns="$2"
			shift 2
			;;
		*) break ;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}

	local profile_input="${1:-${profile_dir_default}}"
	local columns="${opt_columns:-${columns_default}}"
	local sql="SELECT ${columns} FROM keywords;"

	local profile_path
	if [[ "${profile_input}" != /* ]]; then
		profile_path="${chromium_config}/${profile_input}"
	else
		profile_path="${profile_input}"
	fi

	local db_path="${profile_path}/${db_file}"
	[[ ! -f "$db_path" ]] && {
		echo "Error: SQLite DB not found: $db_path" >&2
		return 1
	}

	if ((opt_csv)); then
		sqlite3 -csv "${db_path}" "${sql}"
	else
		sqlite3 -header -column "${db_path}" "${sql}"
	fi
}

chromium.search.engines() { chromium.search.keywords "$@"; }

# chromium.cache.clearAll() {
# 	rm -r ~/.config/chromium/*/Service Worker/CacheStorage
# 	#  "$@"
# 	return $?
# }

# chromium.search.keywords.merge() {
# 	local func_name="${FUNCNAME[0]}"

# 	local chromium_config="$HOME/.config/chromium" # Adjust to your OS/path if needed
# 	local profile_dir=""
# 	local dbfile="Web Data"
# 	local dbpath=""

# 	local usage="
# Usage: $func_name <chromium_profile>
# Queries the Chrome profile's search engines from the Web Data SQLite DB.

# Parameters:
# 	<chromium_profile>  The full path or name of the Chrome profile directory.
# 	|                   If only the name is given, it is resolved inside:
# 	|                   $chromium_config

# Example:
# 	$func_name Default
# 	$func_name /home/user/.config/google-chrome/Profile 3
# "
# 	src_db="$1"
# 	dst_db="$2"
# 	tmpfile=$(mktemp)
# 	local sql_keywords_select="SELECT short_name, keyword, url FROM keywords;"

# 	sqlite3 -csv "$src_db" "${sql_keywords_select}" > "$tmpfile.src"
# 	sqlite3 -csv "$dst_db" "${sql_keywords_select}" > "$tmpfile.dst"

# 	cat "$tmpfile.src" "$tmpfile.dst" | sort | uniq >"$tmpfile.merged"

# 	sqlite3 "$dst_db" "DELETE FROM keywords;"
# 	while IFS=, read -r keyword url short_name; do
# 		sqlite3 "$dst_db" \
# 			"INSERT INTO keywords (keyword, url, short_name) VALUES ('$keyword', '$url', '$short_name');"
# 	done <"$tmpfile.merged"

# 	rm -f "$tmpfile"*
# }

#chromium.fonts.merge() {}

# ── chromium.ext.ls option metadata ──────────────────────────────────────────
#                                          0          1           2      3
_CHROMIUM_EXT_LS_OPTS_SHORT=(-p -b -f -h)
_CHROMIUM_EXT_LS_OPTS_LONG=(--profile --browser --file --help)
_CHROMIUM_EXT_LS_OPTS_ARG=("PROFILE" "BROWSER" "FILE" "")
_CHROMIUM_EXT_LS_OPTS_DESC=(
	"Profile name (default: Default)"
	"Browser prefix (default: chromium)"
	"Direct path to Preferences file"
	"Show help"
)

chromium.ext.ls() {
	local deps=(jq)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			# shellcheck disable=SC2317
			return 127 2>/dev/null || exit 127
		}
	done

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_EXT_LS_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_EXT_LS_OPTS_SHORT[$i]}, ${_CHROMIUM_EXT_LS_OPTS_LONG[$i]}${_CHROMIUM_EXT_LS_OPTS_ARG[$i]:+ ${_CHROMIUM_EXT_LS_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_EXT_LS_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done

	local usage="Usage: $fn [OPTIONS] [PROFILE]
List enabled Chromium extensions.

Options:
$usage_opts
Examples:
	$fn
	$fn 'Profile 1'
	$fn -p 'Profile 1'
	$fn -f ~/custom/Preferences"

	local profile="Default" browser="chromium" file="" showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-p | --profile)
			profile="$2"
			shift 2
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-f | --file)
			file="$2"
			shift 2
			;;
		*) break ;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}

	[[ -z "$file" && -n "${1:-}" ]] && profile="$1"

	local prefs_file="${file:-$HOME/.config/${browser}/${profile}/Preferences}"
	[[ ! -f "$prefs_file" ]] && {
		echo "Error: file not found: $prefs_file" >&2
		return 1
	}

	jq -r '.extensions.settings | to_entries[] | select((.value.disable_reasons // []) | length == 0) | "\(.value.manifest.name)|\(.key)"' \
		"$prefs_file"
}

#chromium.ext.merge() {}

#chromium.ext.conf.merge() {}

# ── Browser config path maps ──────────────────────────────────────────────────
# Native config subdir relative to $HOME/.config/
declare -A _CHROMIUM_NATIVE_CONFIGDIRS=(
	[chromium]="chromium"
	[google - chrome]="google-chrome"
	[google - chrome - stable]="google-chrome"
	[brave - browser]="BraveSoftware/Brave-Browser"
	[vivaldi]="vivaldi"
	[opera]="opera"
	[microsoft - edge]="microsoft-edge"
	[ungoogled - chromium]="chromium"
)
# Flatpak app IDs
declare -A _CHROMIUM_FLATPAK_APPIDS=(
	[chromium]="org.chromium.Chromium"
	[google - chrome]="com.google.Chrome"
	[google - chrome - stable]="com.google.Chrome"
	[brave - browser]="com.brave.Browser"
	[vivaldi]="com.vivaldi.Vivaldi"
	[opera]="com.opera.Opera"
	[microsoft - edge]="com.microsoft.Edge"
	[ungoogled - chromium]="io.github.ungoogled_software.ungoogled_chromium"
)

# ── chromium.config.path option metadata ──────────────────────────────────────
#                                              0          1              2          3
_CHROMIUM_CONFIG_PATH_OPTS_SHORT=(-b -t -I -h)
_CHROMIUM_CONFIG_PATH_OPTS_LONG=(--browser --type --flatpak-id --help)
_CHROMIUM_CONFIG_PATH_OPTS_ARG=("BROWSER" "native|flatpak" "APPID" "")
_CHROMIUM_CONFIG_PATH_OPTS_DESC=(
	"Browser binary name (default: chromium)"
	"Installation type: native or flatpak (default: native)"
	"Override flatpak app ID (flatpak type only)"
	"Show help"
)

# chromium.config.path: resolve browser config base directory
chromium.config.path() {
	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_CONFIG_PATH_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_CONFIG_PATH_OPTS_SHORT[$i]}, ${_CHROMIUM_CONFIG_PATH_OPTS_LONG[$i]}${_CHROMIUM_CONFIG_PATH_OPTS_ARG[$i]:+ ${_CHROMIUM_CONFIG_PATH_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_CONFIG_PATH_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done
	local usage="Usage: $fn [OPTIONS]
Resolve Chromium-based browser config base directory. Does not check existence.

Options:
$usage_opts
Examples:
	$fn
	$fn -b google-chrome
	$fn -b chromium -t flatpak
	$fn -b mybrowser -t flatpak -I com.example.MyBrowser"

	local browser="chromium" type="native" flatpak_id="" showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-t | --type)
			type="$2"
			shift 2
			;;
		-I | --flatpak-id)
			flatpak_id="$2"
			shift 2
			;;
		*) break ;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}

	local subdir="${_CHROMIUM_NATIVE_CONFIGDIRS[$browser]:-$browser}"
	local config_path
	if [[ "$type" == "flatpak" ]]; then
		local appid="${flatpak_id:-${_CHROMIUM_FLATPAK_APPIDS[$browser]:-}}"
		[[ -z "$appid" ]] && {
			echo "Error: no flatpak app ID for browser: $browser" >&2
			printf 'Known browsers: %s\n' "${!_CHROMIUM_FLATPAK_APPIDS[*]}" >&2
			echo "Use -I to specify app ID manually" >&2
			return 1
		}
		config_path="$HOME/.var/app/$appid/config/$subdir"
	else
		config_path="$HOME/.config/$subdir"
	fi

	printf '%s\n' "$config_path"
}

# ── chromium.profile.name option metadata ─────────────────────────────────────
#                                               0          1      2
_CHROMIUM_PROFILE_NAME_OPTS_SHORT=(-b -t -h)
_CHROMIUM_PROFILE_NAME_OPTS_LONG=(--browser --type --help)
_CHROMIUM_PROFILE_NAME_OPTS_ARG=("BROWSER" "native|flatpak" "")
_CHROMIUM_PROFILE_NAME_OPTS_DESC=(
	"Browser binary name (default: chromium)"
	"Installation type: native or flatpak (default: native)"
	"Show help"
)

# chromium.profile.name: resolve display name of a profile dir (reads Preferences .profile.name)
# PROFILE: dir name (e.g. "Default", "Profile 1") or absolute path to profile dir
chromium.profile.name() {
	dep_check jq || return $?

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_PROFILE_NAME_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_PROFILE_NAME_OPTS_SHORT[$i]}, ${_CHROMIUM_PROFILE_NAME_OPTS_LONG[$i]}${_CHROMIUM_PROFILE_NAME_OPTS_ARG[$i]:+ ${_CHROMIUM_PROFILE_NAME_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_PROFILE_NAME_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done
	local usage="Usage: $fn [OPTIONS] PROFILE
Resolve display name of a profile directory (reads Preferences).

PROFILE: dir name relative to config base, or absolute path.

Options:
$usage_opts
Examples:
	$fn Default
	$fn 'Profile 3'
	$fn -b google-chrome Default"

	local browser="chromium" type="native" showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-t | --type)
			type="$2"
			shift 2
			;;
		*) break ;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}

	local profile="${1:-}"
	[[ -z "$profile" ]] && {
		echo "Error: PROFILE required" >&2
		return 1
	}

	local prefs
	if [[ "$profile" == /* ]]; then
		prefs="$profile/Preferences"
	else
		local config_dir
		config_dir="$(chromium.config.path -b "$browser" -t "$type")" || return 1
		prefs="$config_dir/$profile/Preferences"
	fi

	[[ ! -f "$prefs" ]] && {
		echo "Error: Preferences not found: $prefs" >&2
		return 1
	}
	jq -r '.profile.name // empty' "$prefs"
}

# ── chromium.profile.path option metadata ─────────────────────────────────────
#                                               0          1      2
_CHROMIUM_PROFILE_PATH_OPTS_SHORT=(-b -t -h)
_CHROMIUM_PROFILE_PATH_OPTS_LONG=(--browser --type --help)
_CHROMIUM_PROFILE_PATH_OPTS_ARG=("BROWSER" "native|flatpak" "")
_CHROMIUM_PROFILE_PATH_OPTS_DESC=(
	"Browser binary name (default: chromium)"
	"Installation type: native or flatpak (default: native)"
	"Show help"
)

# chromium.profile.path: resolve full path to a profile dir
# NAME resolution order:
#   1. Absolute path → validate + return
#   2. Matches a dir name inside config base → return it
#   3. Matches a display name in Local State profile.info_cache → return matched dir
chromium.profile.path() {
	dep_check jq || return $?

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_PROFILE_PATH_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_PROFILE_PATH_OPTS_SHORT[$i]}, ${_CHROMIUM_PROFILE_PATH_OPTS_LONG[$i]}${_CHROMIUM_PROFILE_PATH_OPTS_ARG[$i]:+ ${_CHROMIUM_PROFILE_PATH_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_PROFILE_PATH_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done
	local usage="Usage: $fn [OPTIONS] NAME
Resolve full path to a profile directory.

NAME: absolute path, dir name (e.g. 'Default'), or profile display name (e.g. 'Work').

Options:
$usage_opts
Examples:
	$fn Default
	$fn Work
	$fn -b google-chrome 'Profile 2'"

	local browser="chromium" type="native" showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-t | --type)
			type="$2"
			shift 2
			;;
		*) break ;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}

	local name="${1:-}"
	[[ -z "$name" ]] && {
		echo "Error: NAME required" >&2
		return 1
	}

	# 1. Absolute path
	if [[ "$name" == /* ]]; then
		[[ ! -d "$name" ]] && {
			echo "Error: profile dir not found: $name" >&2
			return 1
		}
		printf '%s\n' "$name"
		return 0
	fi

	local config_dir
	config_dir="$(chromium.config.path -b "$browser" -t "$type")" || return 1

	[[ ! -d "$config_dir" ]] && {
		echo "Error: config dir not found: $config_dir" >&2
		return 1
	}

	# 2. Direct dir name match
	if [[ -d "$config_dir/$name" ]]; then
		printf '%s\n' "$config_dir/$name"
		return 0
	fi

	# 3. Display name search via Local State
	local local_state="$config_dir/Local State"
	[[ ! -f "$local_state" ]] && {
		echo "Error: Local State not found: $local_state" >&2
		return 1
	}

	local -a matches
	mapfile -t matches < <(jq -r --arg n "$name" \
		'.profile.info_cache | to_entries[] | select(.value.name == $n) | .key' \
		"$local_state")

	[[ ${#matches[@]} -eq 0 ]] && {
		echo "Error: profile not found: $name" >&2
		return 1
	}
	[[ ${#matches[@]} -gt 1 ]] && {
		echo "Error: ambiguous name '$name' matches: ${matches[*]}" >&2
		return 1
	}
	printf '%s\n' "$config_dir/${matches[0]}"
}

# ── chromium.profile.ls option metadata ───────────────────────────────────────
#                                             0          1      2
_CHROMIUM_PROFILE_LS_OPTS_SHORT=(-b -t -h)
_CHROMIUM_PROFILE_LS_OPTS_LONG=(--browser --type --help)
_CHROMIUM_PROFILE_LS_OPTS_ARG=("BROWSER" "native|flatpak" "")
_CHROMIUM_PROFILE_LS_OPTS_DESC=(
	"Browser binary name (default: chromium)"
	"Installation type: native or flatpak (default: native)"
	"Show help"
)

# chromium.profile.ls: list all profiles with display names from Local State
# Output: <dir_name> TAB <display_name>
chromium.profile.ls() {
	dep_check jq || return $?

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_PROFILE_LS_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_PROFILE_LS_OPTS_SHORT[$i]}, ${_CHROMIUM_PROFILE_LS_OPTS_LONG[$i]}${_CHROMIUM_PROFILE_LS_OPTS_ARG[$i]:+ ${_CHROMIUM_PROFILE_LS_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_PROFILE_LS_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done
	local usage="Usage: $fn [OPTIONS]
List all browser profiles by display name (reads Local State).

Output columns: DIR_NAME<TAB>DISPLAY_NAME

Options:
$usage_opts
Examples:
	$fn
	$fn -b google-chrome
	$fn -t flatpak"

	local browser="chromium" type="native" showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-t | --type)
			type="$2"
			shift 2
			;;
		*) break ;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}

	local config_dir
	config_dir="$(chromium.config.path -b "$browser" -t "$type")" || return 1
	local local_state="$config_dir/Local State"
	[[ ! -f "$local_state" ]] && {
		echo "Error: Local State not found: $local_state" >&2
		return 1
	}

	local -a entries
	mapfile -t entries < <(jq -r '.profile.info_cache | to_entries[] | "\(.value.name)\t\(.key)"' "$local_state" | sort)

	local max=0 entry name
	for entry in "${entries[@]}"; do
		name="${entry%%$'\t'*}"
		((${#name} > max)) && max=${#name}
	done
	local width=$((max + 3))

	for entry in "${entries[@]}"; do
		printf "%-${width}s%s\n" "${entry%%$'\t'*}" "${entry#*$'\t'}"
	done
}

# ── chromium.profile.read option metadata ─────────────────────────────────────
#                                              0          1      2
_CHROMIUM_PROFILE_READ_OPTS_SHORT=(-b -t -h)
_CHROMIUM_PROFILE_READ_OPTS_LONG=(--browser --type --help)
_CHROMIUM_PROFILE_READ_OPTS_ARG=("BROWSER" "native|flatpak" "")
_CHROMIUM_PROFILE_READ_OPTS_DESC=(
	"Browser binary name (default: chromium)"
	"Installation type: native or flatpak (default: native)"
	"Show help"
)

# chromium.profile.read: show summary of a profile (name, email, exit state)
chromium.profile.read() {
	dep_check jq || return $?

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_PROFILE_READ_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_PROFILE_READ_OPTS_SHORT[$i]}, ${_CHROMIUM_PROFILE_READ_OPTS_LONG[$i]}${_CHROMIUM_PROFILE_READ_OPTS_ARG[$i]:+ ${_CHROMIUM_PROFILE_READ_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_PROFILE_READ_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done
	local usage="Usage: $fn [OPTIONS] PROFILE
Show profile summary from Preferences (name, email, exit state).

PROFILE: dir name or display name (resolved via chromium.profile.path).

Options:
$usage_opts
Examples:
	$fn Default
	$fn Work
	$fn -b google-chrome 'Profile 2'"

	local browser="chromium" type="native" showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-t | --type)
			type="$2"
			shift 2
			;;
		*) break ;;
		esac
	done

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}

	local name="${1:-}"
	[[ -z "$name" ]] && {
		echo "Error: PROFILE required" >&2
		return 1
	}

	local profile_path
	profile_path="$(chromium.profile.path -b "$browser" -t "$type" "$name")" || return 1
	local prefs="$profile_path/Preferences"
	[[ ! -f "$prefs" ]] && {
		echo "Error: Preferences not found: $prefs" >&2
		return 1
	}

	jq '{
		dir: "'"${profile_path##*/}"'",
		path: "'"$profile_path"'",
		name: .profile.name,
		email: (.account_info[0].email // null),
		exit_type: .profile.exit_type,
		exited_cleanly: .profile.exited_cleanly
	}' "$prefs"
}

# ── chromium.profile.create option metadata ───────────────────────────────────
#                                                0          1      2     3
_CHROMIUM_PROFILE_CREATE_OPTS_SHORT=(-b -t -n -h)
_CHROMIUM_PROFILE_CREATE_OPTS_LONG=(--browser --type --dry-run --help)
_CHROMIUM_PROFILE_CREATE_OPTS_ARG=("BROWSER" "native|flatpak" "" "")
_CHROMIUM_PROFILE_CREATE_OPTS_DESC=(
	"Browser binary name (default: chromium)"
	"Installation type: native or flatpak (default: native)"
	"Print actions without executing"
	"Show help"
)

# chromium.profile.create: create a new profile directory with minimal Preferences
# DIR is auto-assigned as next available "Profile N" slot
chromium.profile.create() {
	dep_check jq || return $?

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_PROFILE_CREATE_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_PROFILE_CREATE_OPTS_SHORT[$i]}, ${_CHROMIUM_PROFILE_CREATE_OPTS_LONG[$i]}${_CHROMIUM_PROFILE_CREATE_OPTS_ARG[$i]:+ ${_CHROMIUM_PROFILE_CREATE_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_PROFILE_CREATE_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done
	local usage="Usage: $fn [OPTIONS] DISPLAY_NAME
Create a new profile directory with minimal Preferences.
Dir is auto-assigned as the next available 'Profile N' slot.
Chromium fills in the rest on first launch.

Options:
$usage_opts
Examples:
	$fn 'Personal'
	$fn -b google-chrome 'Work'
	$fn --dry-run 'Test'"

	local browser="chromium" type="native" dryrun=0 showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-t | --type)
			type="$2"
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

	local display_name="${1:-}"
	[[ -z "$display_name" ]] && {
		echo "Error: DISPLAY_NAME required" >&2
		return 1
	}

	eval "$(dry_run_wrapper)"

	local config_dir
	config_dir="$(chromium.config.path -b "$browser" -t "$type")" || return 1
	[[ ! -d "$config_dir" ]] && {
		echo "Error: config dir not found: $config_dir" >&2
		return 1
	}

	local n=1
	while [[ -d "$config_dir/Profile $n" ]]; do ((n++)); done
	local dir_name="Profile $n"
	local profile_dir="$config_dir/$dir_name"

	run_cmd mkdir -p "$profile_dir" || return 1

	if ((dryrun)); then
		echo "DRY-RUN: write Preferences: name=$display_name exit_type=Normal"
	else
		jq -n --arg name "$display_name" '{
			profile: {
				name: $name,
				exit_type: "Normal",
				exited_cleanly: true
			}
		}' >"$profile_dir/Preferences" || return 1
	fi

	# Register in Local State so chromium.profile.ls sees the new profile
	local local_state="$config_dir/Local State"
	[[ ! -f "$local_state" ]] && {
		echo "Error: Local State not found: $local_state — profile dir created but not registered" >&2
		return 1
	}
	if ((dryrun)); then
		echo "DRY-RUN: register $dir_name in Local State"
	else
		local tmp
		tmp="$(mktemp)" || return 1
		jq --arg d "$dir_name" --arg n "$display_name" \
			'.profile.info_cache[$d] = {name: $n}' \
			"$local_state" >"$tmp" && mv "$tmp" "$local_state" || {
			rm -f "$tmp"
			return 1
		}
	fi

	printf 'Created: %s (%s)\n' "$display_name" "$profile_dir"
}

# ── chromium.profile.copy option metadata ─────────────────────────────────────
#                                              0          1      2          3     4          5
_CHROMIUM_PROFILE_COPY_OPTS_SHORT=(-b -t -s -k -n -h)
_CHROMIUM_PROFILE_COPY_OPTS_LONG=(--browser --type --suffix --keep-sessions --dry-run --help)
_CHROMIUM_PROFILE_COPY_OPTS_ARG=("BROWSER" "native|flatpak" "SUFFIX" "" "" "")
_CHROMIUM_PROFILE_COPY_OPTS_DESC=(
	"Browser binary name (default: chromium)"
	"Installation type: native or flatpak (default: native)"
	"Display name suffix for copy (default: ' (Copy)')"
	"Keep Sessions/ files in copy (default: delete them)"
	"Print actions without executing"
	"Show help"
)

# chromium.profile.copy: copy a profile to next available Profile N slot
# Updates display name in Preferences with suffix; resets exit state to clean
chromium.profile.copy() {
	dep_check jq || return $?

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_PROFILE_COPY_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_PROFILE_COPY_OPTS_SHORT[$i]}, ${_CHROMIUM_PROFILE_COPY_OPTS_LONG[$i]}${_CHROMIUM_PROFILE_COPY_OPTS_ARG[$i]:+ ${_CHROMIUM_PROFILE_COPY_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_PROFILE_COPY_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done
	local usage="Usage: $fn [OPTIONS] SOURCE
Copy a profile to the next available 'Profile N' dir slot.
Display name is suffixed; exit state is reset to clean.
Sessions files are deleted from the copy by default (use --keep-sessions to preserve).

SOURCE: dir name or display name (resolved via chromium.profile.path).

Options:
$usage_opts
Examples:
	$fn Default
	$fn Work
	$fn --suffix ' (Backup)' Default
	$fn -b google-chrome 'Profile 3'"

	local browser="chromium" type="native" suffix=" (Copy)" keep_sessions=0 dryrun=0 showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-t | --type)
			type="$2"
			shift 2
			;;
		-s | --suffix)
			suffix="$2"
			shift 2
			;;
		-k | --keep-sessions)
			keep_sessions=1
			shift
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

	local src="${1:-}"
	[[ -z "$src" ]] && {
		echo "Error: SOURCE required" >&2
		return 1
	}

	eval "$(dry_run_wrapper)"

	local config_dir
	config_dir="$(chromium.config.path -b "$browser" -t "$type")" || return 1

	local src_path
	src_path="$(chromium.profile.path -b "$browser" -t "$type" "$src")" || return 1

	# Prefer Local State name (authoritative, same source as profile.ls) over Preferences
	local src_dir_key="${src_path##*/}"
	local local_state="$config_dir/Local State"
	local src_name
	src_name="$(jq -r --arg d "$src_dir_key" '.profile.info_cache[$d].name // empty' "$local_state" 2>/dev/null)"
	[[ -z "$src_name" ]] && src_name="$(chromium.profile.name -b "$browser" -t "$type" "$src_dir_key" 2>/dev/null)"
	[[ -z "$src_name" ]] && src_name="$src"

	local n=1
	while [[ -d "$config_dir/Profile $n" ]]; do ((n++)); done
	local dst_dir="$config_dir/Profile $n"

	run_cmd cp -r "$src_path" "$dst_dir" || return 1

	local new_name="${src_name}${suffix}"
	local prefs="$dst_dir/Preferences"

	if ((dryrun)); then
		echo "DRY-RUN: patch Preferences: name=$new_name exit_type=Normal"
	else
		[[ -f "$prefs" ]] || {
			echo "Error: Preferences not found in copy: $prefs" >&2
			return 1
		}
		local tmp
		tmp="$(mktemp)" || return 1
		jq --arg n "$new_name" \
			'.profile.name = $n | .profile.exit_type = "Normal" | .profile.exited_cleanly = true' \
			"$prefs" >"$tmp" && mv "$tmp" "$prefs" || {
			rm -f "$tmp"
			return 1
		}
	fi

	# Delete sessions from copy so it doesn't inherit open tabs
	local src_sessions_dir="$src_path/Sessions"
	if [[ -d "$src_sessions_dir" ]]; then
		if ((!keep_sessions)); then
			if ((dryrun)); then
				echo "DRY-RUN: delete Sessions/Session_* Sessions/Tabs_* from copy"
			else
				rm -f "$dst_dir/Sessions"/Session_* "$dst_dir/Sessions"/Tabs_*
			fi
		fi
	fi

	# Register in Local State so chromium.profile.ls sees the copied profile
	local dst_dir_name="${dst_dir##*/}"
	[[ ! -f "$local_state" ]] && {
		echo "Error: Local State not found: $local_state — profile dir created but not registered" >&2
		return 1
	}
	if ((dryrun)); then
		echo "DRY-RUN: register $dst_dir_name in Local State"
	else
		local tmp2
		tmp2="$(mktemp)" || return 1
		jq --arg d "$dst_dir_name" --arg n "$new_name" \
			'.profile.info_cache[$d] = {name: $n}' \
			"$local_state" >"$tmp2" && mv "$tmp2" "$local_state" || {
			rm -f "$tmp2"
			return 1
		}
	fi

	printf 'Copied: %s → %s\n%s\n' "$src_name" "$new_name" "$dst_dir"
}

# ── chromium.profile.update option metadata ───────────────────────────────────
#                                                0          1      2          3     4
_CHROMIUM_PROFILE_UPDATE_OPTS_SHORT=(-b -t -N -n -h)
_CHROMIUM_PROFILE_UPDATE_OPTS_LONG=(--browser --type --name --dry-run --help)
_CHROMIUM_PROFILE_UPDATE_OPTS_ARG=("BROWSER" "native|flatpak" "NAME" "" "")
_CHROMIUM_PROFILE_UPDATE_OPTS_DESC=(
	"Browser binary name (default: chromium)"
	"Installation type: native or flatpak (default: native)"
	"New display name to set in Preferences"
	"Print actions without executing"
	"Show help"
)

# chromium.profile.update: update profile display name in Preferences
chromium.profile.update() {
	dep_check jq || return $?

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_PROFILE_UPDATE_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_PROFILE_UPDATE_OPTS_SHORT[$i]}, ${_CHROMIUM_PROFILE_UPDATE_OPTS_LONG[$i]}${_CHROMIUM_PROFILE_UPDATE_OPTS_ARG[$i]:+ ${_CHROMIUM_PROFILE_UPDATE_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_PROFILE_UPDATE_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done
	local usage="Usage: $fn [OPTIONS] PROFILE --name NEW_NAME
Update profile display name in Preferences.

PROFILE: dir name or display name (resolved via chromium.profile.path).

Options:
$usage_opts
Examples:
	$fn Default --name 'Personal'
	$fn Work -N 'Work 2025'
	$fn -b google-chrome 'Profile 3' --name Dev"

	local browser="chromium" type="native" new_name="" dryrun=0 showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-t | --type)
			type="$2"
			shift 2
			;;
		-N | --name)
			new_name="$2"
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

	local profile="${1:-}"
	[[ -z "$profile" ]] && {
		echo "Error: PROFILE required" >&2
		return 1
	}
	[[ -z "$new_name" ]] && {
		echo "Error: --name NEW_NAME required" >&2
		return 1
	}

	eval "$(dry_run_wrapper)"

	local profile_path
	profile_path="$(chromium.profile.path -b "$browser" -t "$type" "$profile")" || return 1
	local prefs="$profile_path/Preferences"
	[[ ! -f "$prefs" ]] && {
		echo "Error: Preferences not found: $prefs" >&2
		return 1
	}

	if ((dryrun)); then
		echo "DRY-RUN: patch $prefs: .profile.name = $new_name"
	else
		local tmp
		tmp="$(mktemp)" || return 1
		jq --arg n "$new_name" '.profile.name = $n' "$prefs" >"$tmp" &&
			mv "$tmp" "$prefs" || {
			rm -f "$tmp"
			return 1
		}
		printf 'Updated: %s → %s\n' "$profile" "$new_name"
	fi
}

# ── chromium.profile.delete option metadata ───────────────────────────────────
#                                                0          1      2       3     4
_CHROMIUM_PROFILE_DELETE_OPTS_SHORT=(-b -t -f -n -h)
_CHROMIUM_PROFILE_DELETE_OPTS_LONG=(--browser --type --force --dry-run --help)
_CHROMIUM_PROFILE_DELETE_OPTS_ARG=("BROWSER" "native|flatpak" "" "" "")
_CHROMIUM_PROFILE_DELETE_OPTS_DESC=(
	"Browser binary name (default: chromium)"
	"Installation type: native or flatpak (default: native)"
	"Confirm deletion (required)"
	"Print actions without executing"
	"Show help"
)

# WARNING: chromium.profile.delete permanently removes the profile directory and
# all its data (history, cookies, extensions, sessions). This cannot be undone.
# Requires --force to execute.
chromium.profile.delete() {
	dep_check jq || return $?

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_PROFILE_DELETE_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_PROFILE_DELETE_OPTS_SHORT[$i]}, ${_CHROMIUM_PROFILE_DELETE_OPTS_LONG[$i]}${_CHROMIUM_PROFILE_DELETE_OPTS_ARG[$i]:+ ${_CHROMIUM_PROFILE_DELETE_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_PROFILE_DELETE_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done
	local usage="Usage: $fn [OPTIONS] PROFILE
Permanently delete a profile directory and all its data.
Requires --force. Also removes the entry from Local State.

PROFILE: dir name or display name (resolved via chromium.profile.path).

Options:
$usage_opts
Examples:
	$fn --force Default
	$fn -f Work
	$fn --dry-run OldProfile"

	local browser="chromium" type="native" force=0 dryrun=0 showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-t | --type)
			type="$2"
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

	((showhelp)) && {
		printf '%s\n' "$usage"
		return 0
	}

	local profile="${1:-}"
	[[ -z "$profile" ]] && {
		echo "Error: PROFILE required" >&2
		return 1
	}
	((!force && !dryrun)) && {
		echo "Error: --force required to delete a profile" >&2
		return 1
	}

	eval "$(dry_run_wrapper)"

	local profile_path
	profile_path="$(chromium.profile.path -b "$browser" -t "$type" "$profile")" || return 1
	local dir_name="${profile_path##*/}"
	local config_dir="${profile_path%/*}"

	run_cmd rm -rf "$profile_path" || return 1

	# Remove stale entry from Local State
	local local_state="$config_dir/Local State"
	if [[ -f "$local_state" ]]; then
		if ((dryrun)); then
			echo "DRY-RUN: remove .profile.info_cache[\"$dir_name\"] from Local State"
		else
			local tmp
			tmp="$(mktemp)" || return 1
			jq --arg d "$dir_name" 'del(.profile.info_cache[$d])' \
				"$local_state" >"$tmp" && mv "$tmp" "$local_state" || rm -f "$tmp"
		fi
	fi

	printf 'Deleted: %s (%s)\n' "$profile" "$profile_path"
}

# ── chromium.profile.close-tabs option metadata ───────────────────────────────
#                                                     0          1      2                  3     4
_CHROMIUM_PROFILE_CLOSE_TABS_OPTS_SHORT=(-b -t -k -n -h)
_CHROMIUM_PROFILE_CLOSE_TABS_OPTS_LONG=(--browser --type --keep-sessions --dry-run --help)
_CHROMIUM_PROFILE_CLOSE_TABS_OPTS_ARG=("BROWSER" "native|flatpak" "" "" "")
_CHROMIUM_PROFILE_CLOSE_TABS_OPTS_DESC=(
	"Browser binary name (default: chromium)"
	"Installation type: native or flatpak (default: native)"
	"Keep Sessions/ files intact (default: delete them)"
	"Print actions without executing"
	"Show help"
)

# chromium.profile.close-tabs: prevent tab restore on next Chromium launch
# Patches Preferences (exit_type=Normal, exited_cleanly=true) and deletes Sessions/Session_* + Sessions/Tabs_*.
# Use --keep-sessions to skip Sessions deletion.
chromium.profile.close-tabs() {
	dep_check jq || return $?

	local fn="${FUNCNAME[0]}"
	local usage_opts="" i
	for ((i = 0; i < ${#_CHROMIUM_PROFILE_CLOSE_TABS_OPTS_SHORT[@]}; i++)); do
		local sig="${_CHROMIUM_PROFILE_CLOSE_TABS_OPTS_SHORT[$i]}, ${_CHROMIUM_PROFILE_CLOSE_TABS_OPTS_LONG[$i]}${_CHROMIUM_PROFILE_CLOSE_TABS_OPTS_ARG[$i]:+ ${_CHROMIUM_PROFILE_CLOSE_TABS_OPTS_ARG[$i]}}"
		local line
		printf -v line '\t%-32s%s\n' "$sig" "${_CHROMIUM_PROFILE_CLOSE_TABS_OPTS_DESC[$i]}"
		usage_opts+="$line"
	done
	local usage="Usage: $fn [OPTIONS] PROFILE
Prevent tab restore on next Chromium launch.
Patches Preferences + deletes Sessions/Session_* and Sessions/Tabs_* by default.
Use --keep-sessions to preserve session files.

PROFILE: dir name or display name (resolved via chromium.profile.path).

Options:
$usage_opts
Examples:
	$fn Default
	$fn --keep-sessions Work
	$fn -b google-chrome 'Profile 2'"

	local browser="chromium" type="native" keep_sessions=0 dryrun=0 showhelp=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			showhelp=1
			shift
			;;
		-b | --browser)
			browser="$2"
			shift 2
			;;
		-t | --type)
			type="$2"
			shift 2
			;;
		-k | --keep-sessions)
			keep_sessions=1
			shift
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

	local profile="${1:-}"
	[[ -z "$profile" ]] && {
		echo "Error: PROFILE required" >&2
		return 1
	}

	eval "$(dry_run_wrapper)"

	local profile_path
	profile_path="$(chromium.profile.path -b "$browser" -t "$type" "$profile")" || return 1
	local prefs="$profile_path/Preferences"
	[[ ! -f "$prefs" ]] && {
		echo "Error: Preferences not found: $prefs" >&2
		return 1
	}

	if ((dryrun)); then
		echo "DRY-RUN: patch $prefs: exit_type=Normal exited_cleanly=true"
	else
		local tmp
		tmp="$(mktemp)" || return 1
		jq '.profile.exit_type = "Normal" | .profile.exited_cleanly = true' \
			"$prefs" >"$tmp" && mv "$tmp" "$prefs" || {
			rm -f "$tmp"
			return 1
		}
	fi

	if ((!keep_sessions)); then
		local sessions_dir="$profile_path/Sessions"
		if [[ -d "$sessions_dir" ]]; then
			if ((dryrun)); then
				echo "DRY-RUN: delete Sessions/Session_* Sessions/Tabs_*"
			else
				rm -f "$sessions_dir"/Session_* "$sessions_dir"/Tabs_*
			fi
		fi
	fi

	printf 'Closed tabs: %s (%s)\n' "$profile" "$profile_path"
}

export -f chromium.search.keywords chromium.search.engines chromium.ext.ls \
	chromium.config.path \
	chromium.profile.name chromium.profile.path chromium.profile.ls \
	chromium.profile.read chromium.profile.create chromium.profile.copy \
	chromium.profile.update chromium.profile.delete chromium.profile.close-tabs

_chromium.search.keywords_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_CHROMIUM_SEARCH_KEYWORDS_OPTS_SHORT[@]}" "${_CHROMIUM_SEARCH_KEYWORDS_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*) mapfile -t COMPREPLY < <(compgen -W "" -- "$cur") ;;
	esac
}
complete -F _chromium.search.keywords_complete chromium.search.keywords
complete -F _chromium.search.keywords_complete chromium.search.engines

_chromium.ext.ls_complete() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local all_opts=("${_CHROMIUM_EXT_LS_OPTS_SHORT[@]}" "${_CHROMIUM_EXT_LS_OPTS_LONG[@]}")
	case "$cur" in
	-*) mapfile -t COMPREPLY < <(compgen -W "${all_opts[*]}" -- "$cur") ;;
	*) mapfile -t COMPREPLY < <(compgen -f -- "$cur") ;;
	esac
}
complete -F _chromium.ext.ls_complete chromium.ext.ls

register_completion "chromium.config.path" "_CHROMIUM_CONFIG_PATH"
register_completion "chromium.profile.name" "_CHROMIUM_PROFILE_NAME"
register_completion "chromium.profile.path" "_CHROMIUM_PROFILE_PATH"
register_completion "chromium.profile.ls" "_CHROMIUM_PROFILE_LS"
register_completion "chromium.profile.read" "_CHROMIUM_PROFILE_READ"
register_completion "chromium.profile.create" "_CHROMIUM_PROFILE_CREATE"
register_completion "chromium.profile.copy" "_CHROMIUM_PROFILE_COPY"
register_completion "chromium.profile.update" "_CHROMIUM_PROFILE_UPDATE"
register_completion "chromium.profile.delete" "_CHROMIUM_PROFILE_DELETE"
register_completion "chromium.profile.close-tabs" "_CHROMIUM_PROFILE_CLOSE_TABS"
