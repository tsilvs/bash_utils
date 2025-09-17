#!/usr/bin/env bash

chromium.search.keywords() {
	local func_name="${FUNCNAME[0]}"

	local chromium_config="$HOME/.config/chromium"
	local db_file="Web Data"
	local db_path=""
	local profile_dir_default="Default"
	local columns_default="short_name,keyword,url"

	local usage="
Usage: $func_name [--csv] [--columns] <chromium_profile>
Queries the Chrome profile's search engines from the Web Data SQLite DB.

Parameters:
	<chromium_profile>  The full path or name of the Chrome profile directory.
	|                   If only the name is given, it is resolved inside:
	|                   ${chromium_config}
	--csv               Print as a CSV
	--columns           Specify columns: ${columns_default}
	-h, --help          Show this help message

Example:
	$func_name Default
	$func_name \"/home/user/.config/google-chrome/Profile 3\"
	$func_name --csv --columns url Default
"

	local opt_csv=0
	[[ " $* " =~ ' --csv ' ]] && { shift 1; opt_csv=1; }
	local opt_columns=""
	[[ " $* " =~ ' --columns ' ]] && { shift 1; opt_columns=${1}; shift 1; }
	local columns="${opt_columns:-"${columns_default}"}"
	local profile_input="${1:-"${profile_dir_default}"}"

	local sql_keywords_select="SELECT ${columns} FROM keywords;"

	# [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]]
	[[ " $* " =~ ' -h ' || " $* " =~ ' --help ' ]] && { echo -e "${usage}"; return 0; }

	local profile_path=""

	if [[ "${profile_input}" != /* ]]; then
		profile_path="${chromium_config}/${profile_input}"
	else
		profile_path="${profile_input}"
	fi

	db_path="$profile_path/$db_file"

	if [[ ! -f "$db_path" ]]; then
		echo "Error: SQLite DB file not found at: $db_path" >&2
		return 1
	fi

	(( !!opt_csv )) && { sqlite3 -csv "${db_path}" "${sql_keywords_select}"; return $?; }

	sqlite3 -header -column "${db_path}" "${sql_keywords_select}"
}

chromium.search.engines() {
	chromium.search.keywords "$@"
	return $?
}

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

#chromium.ext.merge() {}

#chromium.ext.conf.merge() {}
