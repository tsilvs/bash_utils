#!/usr/bin/env bash

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
	return $?
}

podman.cont.cmd() {
	local container_name="${1:?"Container Name is required"}"
	podman.cont.conf "${container_name}" | jq -r '.Config.Cmd[0]'
	return $?
}

podman.cont.env() {
	[[ ( (( $# == 0 )) ) || ( " $* " =~ ' --help ' ) ]] && {
		echo -e \
"Usage: ${FUNCNAME[0]} IMG_NAME
Show container internal environment for current context.
	--help	Show help";
		return 0;
	}
	(($# > 1)) && { echo -e "Command accepts 1 argument"; return 0; }
	local img_name="${1:?"Image Name is required"}"
	podman.cont.conf "${img_name}" | jq --raw-output '.Config.Env[]'
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

# args.parse() {
# 	# What do I even put here???
# 	# It's probably supposed to somehow support at least --help option and print a helptext that uses a structured list of params and their descriptions, maybe in a JSON
# }

# podman.img.ls() {
# 	# Supposed to just list files inside on an OCI container image
# 	read imagename lsopts <<< $(args.parse "imagename,lsopts" "$@")
# 	local mountpoint="$(podman image mount "${imagename}")"
# 	ls ${lsopts[*]} "${mountpoint}"
# 	# maybe should cleanup after istelf with `podman image unmount`?
# 	return $?
# }

podman.img.conf() {
	local img_name="${1:?"Image Name is required"}"
	podman image inspect "${img_name}" --format json | jq -r '.[0]'
	return $?
}

podman.img.digest() {
	podman.img.conf "$@" | jq -r ".Digest"
	return $?
}

podman.img.sha() {
	podman.img.digest "$@"
	return $?
}

podman.img.cmd() {
	local img_name="${1:?"Image Name is required"}"
	podman.img.conf "${img_name}" | jq -r '.Config.Cmd[0]'
	return $?
}

podman.img.entry() {
	local img_name="${1:?"Image Name is required"}"
	podman.img.conf "${img_name}" | jq -r '.Config.Entrypoint | join(" ")'
	return $?
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
	local img_name="${1:?"Image Name is required"}"
	podman.img.conf "${img_name}" | jq --raw-output '.Config.Env[]'
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
	podman save "${img_name}" | podman load
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

# podman.img.importAll() {
# 	:
# 	# local stdin=???
# 	# cat $stdin | xargs podman pull
# }

# export -f args.parse

export -f podman.commit
export -f podman.root.dir

export -f podman.conts.manif.path
export -f podman.conts.manif

export -f podman.cont.manif
export -f podman.cont.id
export -f podman.cont.dir
export -f podman.cont.conf
# export -f podman.cont.digest
# export -f podman.cont.sha
export -f podman.cont.cmd
# export -f podman.cont.entry
export -f podman.cont.env
# export -f podman.img.mv.root

export -f podman.imgs.manif.path
export -f podman.imgs.manif

export -f podman.img.manif
export -f podman.img.id
export -f podman.img.dir
export -f podman.img.conf
export -f podman.img.digest
export -f podman.img.sha
export -f podman.img.cmd
export -f podman.img.entry
export -f podman.img.env
export -f podman.img.mv.root
# export -f podman.img.ls

export -f podman.conf.path
# export -f podman.conf.merge
# export -f podman.img.importAll

