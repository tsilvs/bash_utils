#!/usr/bin/env bash

#docker.images.ls() {
#	docker images --format "docker-daemon:{{.Repository}}:{{.Tag}}"
#}

docker.user.group.add() {
	sudo usermod --append --groups docker $(id --user --name)
}

docker.root.dir() {
	echo "$(docker info --format json | jq -r '.DockerRootDir')"
}

docker.img.env() {
	(($# > 1)) && { echo -e "Command accepts 1 argument"; return 0; }
	local image_name="${1:?"Image name required"}"
	sudo docker image inspect --format json "${image_name}" | jq --raw-output '.[].Config.Env[]'
}

# docker info | grep 'Docker Root Dir:' | cut -d':' -f2 | sed 's/^ *//g'

# container_id=$(docker ps -a --no-trunc | grep <container_name> | awk '{print $1}')
# echo "Container ID: $container_id"
# echo "Container storage: /var/lib/docker/containers/$container_id"

# image_id=$(docker images --no-trunc | grep <image_name> | awk '{print $3}')
# echo "Image ID: $image_id"
# echo "Image metadata: /var/lib/docker/image/overlay2/imagedb/content/$image_id"

