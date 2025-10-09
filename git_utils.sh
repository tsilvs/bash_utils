#!/usr/bin/env bash

# `_IV` variable suffix stands for `input validation`

git.dir.check() {
	[[ ((($# == 0))) || (" $* " =~ ' --help ') ]] && {
		echo -e "Usage: ${FUNCNAME[0]} REPO_PATH
Checks if the directory is a git repo.
	--help	Displays this help message"
		return 0
	}
	local repo_path="${1:?"Repo path is required"}"
	git -C "${repo_path}" rev-parse >/dev/null 2>&1
	return $?
}

git.url.to_dir() {
	[[ ((($# == 0))) || (" $* " =~ ' --help ') ]] && {
		echo -e "Usage: ${FUNCNAME[0]} REMOTE_URL
Extracts directory name from a git remote url.
	--help	Displays this help message"
		return 0
	}
	local remote_address="${1:?"Remote address is required"}"
	#local author_name="$(basename "$(dirname "${remote_address}")")"
	local author_name="$(echo "${remote_address}" | sed -E 's/.*[:/]([^/]+)\/.*/\1/')"
	local project_name="$(basename "${remote_address}" .git)"
	local target_dir="${author_name}/${project_name}"
	echo -e "${target_dir}"
}

git.clone.to_dir() {
	[[ ((($# == 0))) || (" $* " =~ ' --help ') ]] && {
		echo -e "Usage: ${FUNCNAME[0]} REMOTE_URL [REPO_DIR]
Clones a remote repo to a local dir.
	--help	Displays this help message"
		return 0
	}
	local remote_address="${1:?"Remote address is required"}"
	local target_dir_input="${2:-"$(git.url.to_dir "${remote_address}")"}"
	local target_dir_IV="${target_dir_input:?"Target Dir is required"}"
	local target_dir
	# local repo_root_input="${3:-$(pwd)}"
	local repo_root_input="$(pwd)"
	target_dir="$(realpath -m "${target_dir_IV}")"
	mkdir -p "${target_dir}"
	git -C "${repo_root_input}" clone "${remote_address}" "${target_dir}"
}

git.clone.list() {
	[[ ($# -eq 0) || " $* " =~ ' --help ' ]] && {
		echo -e "Usage: ${FUNCNAME[0]} LIST_FILE_PATH [REPO_ROOT]
Clones a list of remote repos to a local dir.
	--help	Displays this help message"
		return 0
	}
	local list_file_path="${1:?"List file path is required"}"
	[[ -f "${list_file_path}" ]] || {
		echo "List file does not exist"
		return 1
	}
	local repo_root_input="${2:-$(pwd)}"
	local repo_root="$(realpath -m "${repo_root_input}")"
	local remote_list=()
	while IFS= read -r line || [[ -n "$line" ]]; do
		remote_list+=("$line")
	done <"${list_file_path}"
	for remote in "${remote_list[@]}"; do
		[[ -z "${remote}" ]] && continue
		local target_dir="${repo_root}/$(git.url.to_dir "${remote}")"
		git.dir.check "${target_dir}" && { echo "${target_dir} is a Git repo already"; continue; }
		#git.clone.to_dir "${remote}" "${target_dir}"
		git.clone.to_dir "${remote}"
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

