# Bash Utility Functions Library

> Intended for `source` (or `.`).

# Installation

## Define installation function for current session

```sh
bash_utils_install_clone() {
	local install_root="${1}"; [[ -z "${install_root}" ]] && { echo "Installation directory is required"; return 1; }
	local git_remote="${2}"; [[ -z "${git_remote}" ]] && { echo "Git remote is required"; return 1; }
	local author_name="$(basename "$(dirname "${git_remote}")")"
	local project_name="$(basename "${git_remote}" .git)"
	local install_dir="${install_root}/${author_name}/${project_name}"
	local install_dir_rel="$\(realpath $\(dirname \"$\{BASH_SOURCE[0]\}\"\)\)/${author_name}/${project_name}"
	mkdir -p "${install_dir}"
	git clone "${git_remote}" "${install_dir}"
	echo -e "for func_lib in ${install_dir}/*.sh; do
		source \"\${func_lib}\"
	done" >> "${install_root}/source.import.${author_name}.${project_name}.sh"
}
```

## Pick scope path

| User scope    | For all sessions | For interactive sessions |
|---------------|------------------|--------------------------|
| System-wide   | `/etc/profile.d` | `/etc/bashrc.d`          |
| User-specific | `~/.profile.d`   | `~/.bashrc.d`            |

## Install

```sh
sudo bash_utils_install_clone "${scope_path}" git@github.com:tsilvs/bash_utils.git
```