#!/usr/bin/env bash

# Podman-packaged CLI tools Alias Functions

oapi-gen-cli.() {
	podman run -it --rm openapitools/openapi-generator-cli -- docker-entrypoint.sh "$@"
	return $?
}
