#!/bin/bash

podman.commit() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} CONTAINER_NAME [IMAGE_NAME]
Commit container to an image.
	--help	Show help";
		return 0;
	}
	local container_name="${1:?"Container Name is required"}"
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

#podman.images.all() {}
	#echo ${a_path#*/var}
	#jq --raw-output

podman.root.path() {
	[[ ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]}
Show container location for current context.
	--help	Show help";
		return 0;
	}
	local podman_yaml="$(podman info)"
	local podman_path_store="$(echo "${podman_yaml}" | yq '.store.graphRoot')"
	echo "${podman_path_store}"
}

podman.cont.id() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} CONTAINER_NAME
Show container ID for current context.
	--help	Show help";
		return 0;
	}
	local container_name="${1:?"Container Name is required"}"
	local podman_path_store="$(podman.root.path)"
	local podman_containers_json="$(jq --raw-input 'fromjson' "${podman_path_store}/overlay-containers/containers.json")"
	local container_json="$(echo "${podman_containers_json}" | jq --arg name "${container_name}" '.[] | select(.names[0] == $name)')"
	local container_id="$(echo "${container_json}" | jq --raw-output '.id')"
	echo "${container_id}"
}

podman.cont.dir() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} CONTAINER_NAME
Show container location for current context.
	--help	Show help";
		return 0;
	}
	local container_name="${1:?"Container Name is required"}"
	local podman_yaml="$(podman info)"
	local podman_path_store="$(podman.root.path)"
	local container_id="$(podman.cont.id "${container_name}")"
	echo "${podman_path_store}/overlay-containers/${container_id}"
}

podman.img.id() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} IMG_NAME
Show image ID for current context.
	--help	Show help";
		return 0;
	}
	local img_name="${1:?"Image Name is required"}"
	local podman_path_store="$(podman.root.path)"
	local podman_images_json="$(jq --raw-input 'fromjson' "${podman_path_store}/overlay-images/images.json")"
	local img_json="$(echo "${podman_images_json}" | jq --arg name "${img_name}" '.[] | select(.names[0] == $name)')"
	local img_id="$(echo "${img_json}" | jq --raw-output '.id')"
	echo "${img_id}"
}

podman.img.dir() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} IMG_NAME
Show image location for current context.
	--help	Show help";
		return 0;
	}
	local image_name="${1:?"Image Name is required"}"
	local podman_yaml="$(podman info)"
	local podman_path_store="$(podman.root.path)"
	local image_id="$(podman.img.id "${image_name}")"
	echo "${podman_path_store}/overlay-images/${image_id}"
}

podman.conf.path() {
	[[ ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]}
Show config location for current context.
	--help	Show help";
		return 0;
	}
	local podman_yaml="$(podman info)"
	local podman_path_config="$(dirname "$(echo "${podman_yaml}" | yq '.store.configFile')")"
	echo "${podman_path_config}"
}

#podman.conf.merge() {
#	local conf_path_1="${1:?"Config 1 path is required"}"
#	local conf_path_2="${2:?"Config 2 path is required"}"
#}