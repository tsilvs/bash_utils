#!/usr/bin/env bash

# Podman-packaged CLI tools Alias Functions

oapigen.() {
	oapigen_run() {
		podman run \
			-it \
			--rm \
			-w /home/ubuntu/pwd \
			-v "$(pwd)":/home/ubuntu/pwd:Z \
			openapitools/openapi-generator-cli \
			"$@"
	}
	oapigen_run "$@"
	return $?
}
