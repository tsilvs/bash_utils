#!/usr/bin/env bash

# `_IV` variable suffix stands for `input validation`

#!/usr/bin/env bash

git.dir.check() {
	local repo_path="" show_help=false dry_run=false
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help) show_help=true; shift ;;
			-n|--dry-run) dry_run=true; shift ;;
			-*) echo "Unknown option: $1" >&2; return 1 ;;
			*) repo_path="$1"; shift ;;
		esac
	done
	
	${show_help} && {
		cat <<-EOF
		Usage: ${FUNCNAME[0]} [OPTIONS] REPO_PATH
		Checks if directory is git repo.
		
		Options:
		  -h, --help       Display this help message
		  -n, --dry-run    Show command without executing
		EOF
		return 0
	}
	
	[[ -z "${repo_path}" ]] && { echo "Repo path required" >&2; return 1; }
	
	local run="git -C '${repo_path}' rev-parse >/dev/null 2>&1"
	${dry_run} && { echo "${run}"; return 0; }
	eval "${run}"
}

git.url.to_dir() {
	local remote_address="" show_help=false
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help) show_help=true; shift ;;
			-*) echo "Unknown option: $1" >&2; return 1 ;;
			*) remote_address="$1"; shift ;;
		esac
	done
	
	${show_help} && {
		cat <<-EOF
		Usage: ${FUNCNAME[0]} [OPTIONS] REMOTE_URL
		Extracts directory name from git remote url.
		
		Options:
		  -h, --help    Display this help message
		EOF
		return 0
	}
	
	[[ -z "${remote_address}" ]] && { echo "Remote address required" >&2; return 1; }
	
	local author_name="$(echo "${remote_address}" | sed -E 's/.*[:/]([^/]+)\/.*/\1/')"
	local project_name="$(basename "${remote_address}" .git)"
	echo "${author_name}/${project_name}"
}

git.clone.to_dir() {
	local remote_address="" target_dir="" show_help=false dry_run=false
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help) show_help=true; shift ;;
			-n|--dry-run) dry_run=true; shift ;;
			-d|--dir) target_dir="$2"; shift 2 ;;
			-*) echo "Unknown option: $1" >&2; return 1 ;;
			*) 
				[[ -z "${remote_address}" ]] && { remote_address="$1"; shift; continue; }
				[[ -z "${target_dir}" ]] && { target_dir="$1"; shift; continue; }
				shift
				;;
		esac
	done
	
	${show_help} && {
		cat <<-EOF
		Usage: ${FUNCNAME[0]} [OPTIONS] REMOTE_URL [TARGET_DIR]
		Clones remote repo to local dir.
		
		Options:
		  -h, --help         Display this help message
		  -n, --dry-run      Show commands without executing
		  -d, --dir DIR      Target directory path
		EOF
		return 0
	}
	
	[[ -z "${remote_address}" ]] && { echo "Remote address required" >&2; return 1; }
	[[ -z "${target_dir}" ]] && target_dir="$(git.url.to_dir "${remote_address}")"
	
	local repo_root="$(pwd)"
	target_dir="$(realpath -m "${target_dir}")"
	
	local run="mkdir -p '${target_dir}' && git -C '${repo_root}' clone '${remote_address}' '${target_dir}'"
	${dry_run} && { echo "${run}"; return 0; }
	eval "${run}"
}

git.clone.list() {
	local list_file="" repo_root="" show_help=false dry_run=false
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help) show_help=true; shift ;;
			-n|--dry-run) dry_run=true; shift ;;
			-r|--root) repo_root="$2"; shift 2 ;;
			-*) echo "Unknown option: $1" >&2; return 1 ;;
			*) 
				[[ -z "${list_file}" ]] && { list_file="$1"; shift; continue; }
				[[ -z "${repo_root}" ]] && { repo_root="$1"; shift; continue; }
				shift
				;;
		esac
	done
	
	${show_help} && {
		cat <<-EOF
		Usage: ${FUNCNAME[0]} [OPTIONS] LIST_FILE [REPO_ROOT]
		Clones list of remote repos to local dir.
		
		Options:
		  -h, --help         Display this help message
		  -n, --dry-run      Show commands without executing
		  -r, --root DIR     Repository root directory
		EOF
		return 0
	}
	
	[[ -z "${list_file}" ]] && { echo "List file path required" >&2; return 1; }
	[[ ! -f "${list_file}" ]] && { echo "List file doesn't exist" >&2; return 1; }
	[[ -z "${repo_root}" ]] && repo_root="$(pwd)"
	
	repo_root="$(realpath -m "${repo_root}")"
	
	local remote_list=()
	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ -n "${line}" ]] && remote_list+=("$line")
	done <"${list_file}"
	
	for remote in "${remote_list[@]}"; do
		local target_dir="${repo_root}/$(git.url.to_dir "${remote}")"
		
		git.dir.check "${target_dir}" && {
			echo "${target_dir} is git repo already"
			continue
		}
		
		local run="mkdir -p '${target_dir}' && git -C '${repo_root}' clone '${remote}' '${target_dir}'"
		${dry_run} && { echo "${run}"; continue; }
		eval "${run}"
	done
}



# license.get() {
# 	local license_code
# 	local license_tpl_path
# }

# coc.get() {
# 	local coc_code
# 	local coc_tpl_path
# }

# readme.get() {
# 	local readme_tpl_path
# }

# example_struct="
# ./
# 	lib/
# 	src/
# 	.gitignore
# 	CODE_OF_CONDUCT.md
# 	LICENSE.md
# 	README.md
# "

# fs.tree.spawn() {
# 	local struct
# }

# git.init.proj() {
# 	fs.tree.spawn struct
# }

# git.remote.repo.init() {
# 	read -s -p "Enter your API key" -t $TIMEOUT TOKEN
# 	local REPO_DATA # read from a file - repo.json
# 	# or assume folder name as project name and local user name as remote user name as defaults
# 	# and read with a prompt for actual values
# 	# maybe even handle this in `npm init` manner with generation of an analog of `package.json`
# 	local API_ENDPOINT
# 		# GitHub: "${api_domain}/user/repos"
# 		# GitLab: "${api_domain}/api/v4/projects"
# 		# Gitea: "${api_domain}/api/v1/user/repos"
# 	local API_HEADERS
# 		# --header "Authorization: token ${TOKEN}" \
# 		# --header "PRIVATE-TOKEN: ${TOKEN}" \
# 		# --header "Accept: application/vnd.github+json" \
# 		# --header "Content-Type: application/json" \
# 	local TIMEOUT=10
# 	curl \
# 		--include \
# 		--verbose \
# 		--location \
# 		--request POST \
# 		"${API_HEADERS}" \
# 		--data-raw "${REPO_DATA}" \
# 		--data "${REPO_DATA}" \
# 		"${API_ENDPOINT}"
# }

# git.localhost.setup() {
# 	# Setup steps to create a local non-graphical `git` Linux user and allow SSHing to it
# }

# git.dirs.noremote() {
# 	# prints directories with git repos that don't have a specific remote specified
# 	local remote="${1?"Remote name is required."}"
# 	for d in */; do
# 	if [[ -d "$d/.git/config" && grep -q "url =.*lan" "$d/.git/config" ]]; then
# 		continue
# 	fi
# 		echo "$d"
# 	done
# }

