#!/bin/bash

podman_commit() {
	[[ ( -z "$#" ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: podman_commit CONTAINER_NAME [IMAGE_NAME]
Commit container to an image.
	--help	Show help";
		return 0;
	}
	local container_name="${1}"; [[ -z "$container_name" ]] && { echo "Container Name is required"; return 1; }
	local uname="$(id --user --name)"
	local suffix="${uname}"
	local image_name=${2:-"img_${container_name}_${suffix}"}
	#local image_id_file_path="$(pwd)/${image_name}.iidfile"
	local image_id=$(podman commit \
		--quiet \
		--pause=true \
		--author "${uname}" \
		--format oci \
		--squash \
		"${container_name}" \
		"${image_name}")

	#	--iidfile ${image_id_file_path} \

	echo -e "${image_name}\t${image_id}"
}
