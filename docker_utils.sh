#!/bin/bash

#docker.images.ls() {
#	docker images --format "docker-daemon:{{.Repository}}:{{.Tag}}"
#}

docker.image.env() {
	(($# > 1)) && { echo -e "Command accepts 1 argument"; return 0; }
	local image_name="${1:?"Image name required"}"
	sudo docker image inspect --format json "${image_name}" | jq -r '.[].Config.Env[]'
}