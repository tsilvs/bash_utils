# #!/usr/bin/env bash

# # Get workspace ID for current directory
# code.workspace.id() {
# 	local storage_path="${1:-$HOME/.config/Code/User/workspaceStorage}"
# 	grep -l "file://$(pwd)" "$storage_path"/*/workspace.json 2>/dev/null \
# 		| cut -d/ -f-2 --complement | cut -d/ -f1
# }

# # Compare enabled/disabled extensions with recommendations
# code.ext.check() {
# 	local storage_path="$HOME/.config/Code/User/workspaceStorage"
# 	local rec_file=".vscode/extensions.json"
# 	local show_id=0
	
# 	while [ $# -gt 0 ]; do
# 		case "$1" in
# 			-s|--storage) storage_path="$2"; shift 2 ;;
# 			-r|--recommendations) rec_file="$2"; shift 2 ;;
# 			-i|--show-id) show_id=1; shift ;;
# 			-h|--help)
# 				echo "Usage: vscode_ext_check [-s storage_path] [-r rec_file] [-i]"
# 				return 0 ;;
# 			*) shift ;;
# 		esac
# 	done
	
# 	local ws_id=$(code.workspace.id "$storage_path")
# 	[ -z "$ws_id" ] && echo "Workspace ID not found" && return 1
# 	[ $show_id -eq 1 ] && echo "Workspace ID: $ws_id"
	
# 	local db="$storage_path/$ws_id/state.vdb"
# 	local disabled=$(sqlite3 "$db" \
# 		"SELECT value FROM ItemTable WHERE key='extensionsIdentifiers/disabled'" 2>/dev/null \
# 		| jq -r '.[]' 2>/dev/null || echo "")
	
# 	local installed=$(code --list-extensions)
# 	local enabled=$(echo "$installed" | grep -vFf <(echo "$disabled"))
# 	local recommended=$(jq -r '.recommendations[]' "$rec_file" 2>/dev/null || echo "")
	
# 	echo "=== Enabled but not recommended ==="
# 	comm -23 <(echo "$enabled" | sort) <(echo "$recommended" | sort)
	
# 	echo -e "\n=== Recommended but not enabled ==="
# 	comm -23 <(echo "$recommended" | sort) <(echo "$enabled" | sort)
	
# 	echo -e "\n=== Recommended but disabled ==="
# 	comm -12 <(echo "$disabled" | sort) <(echo "$recommended" | sort)
# }

