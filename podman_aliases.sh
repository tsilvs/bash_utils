#!/usr/bin/env bash

# Podman-packaged CLI tools Alias Functions

oapigen.() {
	podman run \
		-it \
		--rm \
		-v "$(pwd)":/home/ubuntu/pwd:Z \
		openapitools/openapi-generator-cli \
		-- \
		bash -c "cd /home/ubuntu/pwd; docker-entrypoint $@"
	return $?
}
