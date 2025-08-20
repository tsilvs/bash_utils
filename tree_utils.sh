#!/bin/bash

tree.() {
	tree -a --gitignore -I '.git' -F --noreport --dirsfirst "$@"
	return $?
}

tree.paths() {
	tree. -i -f "$@"
	return $?
}

tree.paths.d() {
	tree.paths -d "$@"
	return $?
}

tree.json() {
	tree. -J "$@" | jq
	return $?
}

tree.yaml() {
	tree.json "$@" | yq --input-format json
	return $?
}