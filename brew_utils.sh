#!/usr/bin/env bash

# # main () {

# # set -o errexit;
# # set -o pipefail;
# # set -o nounset;

# # local -r __dirname="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
# # local -r __filename="${__dirname}/$(basename "${BASH_SOURCE[0]}")";

# # exit 0;};main "$@";

# brew.r.etc.link() {
# 	local verbose=0
# 	local target_dir="/etc"
# 	local func_name=${FUNCNAME[0]}
# 	local cellar_r_dir="/home/linuxbrew/.linuxbrew/Cellar/r/"
# 	local latest_version_dir
# 	local src_dir

# 	# Parse options
# 	while (( "$#" )); do
# 		case "$1" in
# 			--verbose|-V) verbose=1; shift ;;
# 			--target_dir=*) target_dir="${1#*=}"; shift ;;
# 			--target_dir) target_dir="$2"; shift 2 ;;
# 			--help|-h)
# 				echo "Usage: ${func_name} [--verbose|-V] [--target_dir=PATH]"
# 				return 0 ;;
# 			*) break ;;
# 		esac
# 	done

# 	latest_version_dir=$(ls -1d "${cellar_r_dir}"*/ 2>/dev/null | sort -V | tail -n1)
# 	if [[ -z "$latest_version_dir" ]]; then
# 		echo "No R versions found in $cellar_r_dir" >&2
# 		return 1
# 	fi

# 	src_dir="${latest_version_dir}lib/R/etc"
# 	if [[ ! -d "$src_dir" ]]; then
# 		echo "Source etc directory not found: $src_dir" >&2
# 		return 1
# 	fi

# 	[[ ! -d "$target_dir" ]] && { (( verbose )) && echo "Creating $target_dir"; mkdir -p "$target_dir" || { echo "Failed to create $target_dir" >&2; return 1; }; }

# 	for file in Renviron Rprofile.site; do
# 		local src_path="$src_dir/$file"
# 		local target_path="$target_dir/$file"

# 		if [[ -e "$target_path" && ! -L "$target_path" ]]; then
# 			(( verbose )) && echo "Backing up existing $target_path to ${target_path}.bak"
# 			mv "$target_path" "${target_path}.bak" || { echo "Backup failed for $target_path" >&2; continue; }
# 		fi

# 		if [[ ! -e "$target_path" ]]; then
# 			if [[ -e "$src_path" ]]; then
# 				(( verbose )) && echo "Moving $src_path to $target_path"
# 				mv "$src_path" "$target_path" || { echo "Move failed for $src_path" >&2; continue; }
# 			else
# 				(( verbose )) && echo "$src_path does not exist, skipping"
# 				continue
# 			fi
# 		fi

# 		if [[ -L "$target_path" ]]; then
# 			(( verbose )) && echo "Removing existing symlink $target_path"
# 			rm -f "$target_path"
# 		fi

# 		(( verbose )) && echo "Linking $target_path -> $src_path"
# 		ln -s "$src_path" "$target_path"
# 	done

# 	(( verbose )) && echo "Renviron and Rprofile.site synced to $target_dir"
# }