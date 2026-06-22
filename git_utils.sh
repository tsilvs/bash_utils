#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

# ── git.dir.check option metadata ─────────────────────────────────────────────
_GIT_DIR_CHECK_OPTS_SHORT=(-h -n)
_GIT_DIR_CHECK_OPTS_LONG=(--help --dry-run)
_GIT_DIR_CHECK_OPTS_ARG=("" "")
_GIT_DIR_CHECK_OPTS_DESC=("Display this help message" "Show command without executing")

# ── git.url.to_dir option metadata ────────────────────────────────────────────
_GIT_URL_TO_DIR_OPTS_SHORT=(-h)
_GIT_URL_TO_DIR_OPTS_LONG=(--help)
_GIT_URL_TO_DIR_OPTS_ARG=("")
_GIT_URL_TO_DIR_OPTS_DESC=("Display this help message")

# ── git.clone.to_dir option metadata ──────────────────────────────────────────
_GIT_CLONE_TO_DIR_OPTS_SHORT=(-h -n -d)
_GIT_CLONE_TO_DIR_OPTS_LONG=(--help --dry-run --dir)
_GIT_CLONE_TO_DIR_OPTS_ARG=("" "" "DIR")
_GIT_CLONE_TO_DIR_OPTS_DESC=("Display this help message" "Show commands without executing" "Target directory path")

# ── git.clone.list option metadata ────────────────────────────────────────────
_GIT_CLONE_LIST_OPTS_SHORT=(-h -n -r)
_GIT_CLONE_LIST_OPTS_LONG=(--help --dry-run --root)
_GIT_CLONE_LIST_OPTS_ARG=("" "" "DIR")
_GIT_CLONE_LIST_OPTS_DESC=("Display this help message" "Show commands without executing" "Repository root directory")

# ── git.remote.set_url option metadata ────────────────────────────────────────
_GIT_REMOTE_SET_URL_OPTS_SHORT=(-h -n -r -u -p -s)
_GIT_REMOTE_SET_URL_OPTS_LONG=(--help --dry-run --remote --user --project --host-suffix)
_GIT_REMOTE_SET_URL_OPTS_ARG=("" "" "NAME" "USER" "REPO" "SUF")
_GIT_REMOTE_SET_URL_OPTS_DESC=(
	"Display this help message"
	"Show command without executing"
	"Remote name (default: origin)"
	"User/org name (default: parent dir name)"
	"Repository name (default: current dir name)"
	"SSH host suffix (default: gh)"
)

git.dir.check() {
	local repo_path="" show_help=0 dryrun=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help=1
			shift
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*)
			repo_path="$1"
			shift
			;;
		esac
	done

	eval "$(build_usage "GIT_DIR_CHECK" "${FUNCNAME[0]}" "REPO_PATH" "Checks if directory is git repo.")"
	((show_help)) && {
		printf '%s\n' "$usage"
		return 0
	}

	dep_check git || return

	[[ -z "${repo_path}" ]] && {
		echo "Repo path required" >&2
		return 1
	}

	eval "$(dry_run_wrapper)"
	if ((dryrun)); then
		run_cmd git -C "${repo_path}" rev-parse
	else
		git -C "${repo_path}" rev-parse >/dev/null 2>&1
	fi
}

git.url.to_dir() {
	local remote_address="" show_help=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help=1
			shift
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*)
			remote_address="$1"
			shift
			;;
		esac
	done

	eval "$(build_usage "GIT_URL_TO_DIR" "${FUNCNAME[0]}" "REMOTE_URL" "Extracts directory name from git remote url.")"
	((show_help)) && {
		printf '%s\n' "$usage"
		return 0
	}

	dep_check sed || return

	[[ -z "${remote_address}" ]] && {
		echo "Remote address required" >&2
		return 1
	}

	local author_name
	author_name="$(echo "${remote_address}" | sed -E 's/.*[:/]([^/]+)\/.*/\1/')"
	local project_name
	project_name="$(basename "${remote_address}" .git)"
	echo "${author_name}/${project_name}"
}

git.clone.to_dir() {
	local remote_address="" target_dir="" show_help=0 dryrun=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help=1
			shift
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		-d | --dir)
			target_dir="$2"
			shift 2
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*)
			[[ -z "${remote_address}" ]] && {
				remote_address="$1"
				shift
				continue
			}
			[[ -z "${target_dir}" ]] && {
				target_dir="$1"
				shift
				continue
			}
			shift
			;;
		esac
	done

	eval "$(build_usage "GIT_CLONE_TO_DIR" "${FUNCNAME[0]}" "REMOTE_URL [TARGET_DIR]" "Clones remote repo to local dir.")"
	((show_help)) && {
		printf '%s\n' "$usage"
		return 0
	}

	dep_check git || return

	[[ -z "${remote_address}" ]] && {
		echo "Remote address required" >&2
		return 1
	}
	[[ -z "${target_dir}" ]] && target_dir="$(git.url.to_dir "${remote_address}")"

	local repo_root
	repo_root="$(pwd)"
	target_dir="$(realpath -m "${target_dir}")"

	eval "$(dry_run_wrapper)"
	run_cmd mkdir -p "${target_dir}" && run_cmd git -C "${repo_root}" clone "${remote_address}" "${target_dir}"
}

git.clone.list() {
	local list_file="" repo_root="" show_help=0 dryrun=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help=1
			shift
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		-r | --root)
			repo_root="$2"
			shift 2
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*)
			[[ -z "${list_file}" ]] && {
				list_file="$1"
				shift
				continue
			}
			[[ -z "${repo_root}" ]] && {
				repo_root="$1"
				shift
				continue
			}
			shift
			;;
		esac
	done

	eval "$(build_usage "GIT_CLONE_LIST" "${FUNCNAME[0]}" "LIST_FILE [REPO_ROOT]" "Clones list of remote repos to local dir.")"
	((show_help)) && {
		printf '%s\n' "$usage"
		return 0
	}

	dep_check git || return

	[[ -z "${list_file}" ]] && {
		echo "List file path required" >&2
		return 1
	}
	[[ ! -f "${list_file}" ]] && {
		echo "List file doesn't exist" >&2
		return 1
	}
	[[ -z "${repo_root}" ]] && repo_root="$(pwd)"

	repo_root="$(realpath -m "${repo_root}")"

	local remote_list=()
	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ -n "${line}" ]] && remote_list+=("$line")
	done <"${list_file}"

	eval "$(dry_run_wrapper)"
	for remote in "${remote_list[@]}"; do
		local target_dir="${repo_root}/$(git.url.to_dir "${remote}")"

		git.dir.check "${target_dir}" && {
			echo "${target_dir} is git repo already"
			continue
		}

		run_cmd mkdir -p "${target_dir}" && run_cmd git -C "${repo_root}" clone "${remote}" "${target_dir}"
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

git.remote.set_url() {
	local remote_name="origin" user="" repo="" host_suffix="gh" show_help=0 dryrun=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help=1
			shift
			;;
		-n | --dry-run)
			dryrun=1
			shift
			;;
		-r | --remote)
			remote_name="$2"
			shift 2
			;;
		-u | --user)
			user="$2"
			shift 2
			;;
		-p | --project)
			repo="$2"
			shift 2
			;;
		-s | --host-suffix)
			host_suffix="$2"
			shift 2
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*) shift ;;
		esac
	done

	eval "$(build_usage "GIT_REMOTE_SET_URL" "${FUNCNAME[0]}" "" "Sets git remote URL to SSH format derived from cwd.")"
	((show_help)) && {
		printf '%s\n' "$usage"
		return 0
	}

	dep_check git || return

	[[ -z "${user}" ]] && user="$(basename "$(dirname "$(pwd)")")"
	[[ -z "${repo}" ]] && repo="$(basename "$(pwd)")"

	local url="git@${user}.${host_suffix}:${user}/${repo}.git"
	eval "$(dry_run_wrapper)"
	run_cmd git remote set-url "${remote_name}" "${url}"
}

register_completion "git.dir.check" "GIT_DIR_CHECK"
register_completion "git.url.to_dir" "GIT_URL_TO_DIR"
register_completion "git.clone.to_dir" "GIT_CLONE_TO_DIR"
register_completion "git.clone.list" "GIT_CLONE_LIST"
register_completion "git.remote.set_url" "GIT_REMOTE_SET_URL"

export -f git.dir.check git.url.to_dir git.clone.to_dir git.clone.list git.remote.set_url
