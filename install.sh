#!/usr/bin/env bash

bash_utils.install.clone() {
	local install_root="${1:?"Installation directory is required"}"
	local git_remote="${2:?"Git remote is required"}"
	local author_name="$(echo "${git_remote}" | sed -E 's/.*[:/]([^/]+)\/.*/\1/')"
	local project_name="$(basename "${git_remote}" .git)"
	local install_dir="${install_root}/${author_name}/${project_name}"
	local install_dir_rel="\$(realpath \$(dirname \"\${BASH_SOURCE[0]}\"))/${author_name}/${project_name}"
	mkdir -p "${install_dir}"
	git clone "${git_remote}" "${install_dir}"
	# This will generate a recursive importer script that goes exactly 2 levels deep in the file tree - to author and then to repo itself
	echo -e "for func_lib in ${install_dir_rel}/*.sh; do
		source \"\${func_lib}\"
	done" >> "${install_root}/source.import.${author_name}.${project_name}.sh"
}