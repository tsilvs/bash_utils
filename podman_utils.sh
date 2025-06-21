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

podman.root.dir() {
	[[ ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]}
Show container location for current context.
	--help	Show help";
		return 0;
	}
	podman info | yq '.store.graphRoot'
}

podman.conts.manif.path() {
	[[ ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]}
Show containers manifest path for current context.
	--help	Show help";
		return 0;
	}
	echo "$(podman.root.dir)/overlay-containers/containers.json"
}

podman.conts.manif() {
	[[ ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]}
Show containers manifest for current context.
	--help	Show help";
		return 0;
	}
	echo "$(jq --raw-input 'fromjson' "$(podman.conts.manif.path)")"
}

podman.cont.manif() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} CONTAINER_NAME
Show container manifest for current context.
	--help	Show help";
		return 0;
	}
	local container_name="${1:?"Container Name is required"}"
	podman.conts.manif | jq --arg name "${container_name}" '.[] | select(.names[0] == $name)'
}

podman.cont.conf() {
	local container_name="${1:?"Container Name is required"}"
	podman container inspect "${container_name}" --format json | jq -r '.[0]'
	# | jq -r '.[0].Mounts[]'
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
	podman.cont.manif "${container_name}" | jq --raw-output '.id'
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
	echo "$(podman.root.dir)/overlay-containers/$(podman.cont.id "${container_name}")"
}

podman.imgs.manif.path() {
	[[ ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]}
Show images manifest path for current context.
	--help	Show help";
		return 0;
	}
	echo "$(podman.root.dir)/overlay-images/images.json"
}

podman.imgs.manif() {
	[[ ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]}
Show images manifest for current context.
	--help	Show help";
		return 0;
	}
	echo "$(jq --raw-input 'fromjson' "$(podman.imgs.manif.path)")"
}

podman.img.manif() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} IMG_NAME
Show image manifest for current context.
Params:
	IMG_NAME	image name WITH VERSION (e.g. host/image:latest)
Options:
	--help	Show help";
		return 0;
	}
	local img_name="${1:?"Image Name is required"}"
	podman.imgs.manif | jq --arg name "${img_name}" '.[] | select(.names[0] == $name)'
}

podman.img.conf() {

}

podman.img.id() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} IMG_NAME
Show image ID for current context.
Params:
	IMG_NAME	image name WITH VERSION (e.g. host/image:latest)
Options:
	--help	Show help";
		return 0;
	}
	local img_name="${1:?"Image Name is required"}"
	podman.img.manif "${img_name}" | jq --raw-output '.id'
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
	echo "$(podman.root.dir)/overlay-images/$(podman.img.id "${image_name}")"
}

podman.img.env() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} IMG_NAME
Show image internal environment for current context.
	--help	Show help";
		return 0;
	}
	(($# > 1)) && { echo -e "Command accepts 1 argument"; return 0; }
	local image_name="${1:?"Image name required"}"
	sudo docker image inspect --format json "${image_name}" | jq --raw-output '.[].Config.Env[]'
}

podman.img.mv.root() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} IMG_NAME
Move image to root.
Params:
	IMG_NAME	image name WITH VERSION (e.g. host/image:latest)
Options:
	--help	Show help";
		return 0;
	}
	local img_name="${1:?"Image Name is required"}"
	podman save "${img_name}" | sudo podman load
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

# podman.conf.merge() {
# 	local conf_path_1="${1:?"Config 1 path is required"}"
# 	local conf_path_2="${2:?"Config 2 path is required"}"
# 	local merged_conf=""
# 	echo "${merged_conf}"
# }