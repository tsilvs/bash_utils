#!/usr/bin/env bash

# Podman-packaged CLI tools Alias Functions

oapi-gen-cli.() {
	podman run \
		-it \
		--rm \
		-v "$(pwd)":/home/ubuntu/pwd \
		openapitools/openapi-generator-cli \
		-- \
		bash -c "cd /home/ubuntu/pwd; docker-entrypoint.sh $@"
	return $?
}
