#!/usr/bin/env bash

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

# tree.meta() {
# 	# TODO: Read per-directory $dir/.meta annotations, print inline with tree output.
# 	# $dir/.meta format (tab-separated):
# 	# .	This dir's description
# 	# subdir	subdir description
# 	# file		file description
# 	tree. "$@"
# 	return $?
# }
#
# tree.sim() {
# 	local opts # all proper `tree` options
# 	# TODO: Process options
# 	local pathexpan # should be the last option from all passed params
# 	# Example H1/H2/F{1..3}.ext
# 	tree $opts --fromfile <(printf "%s\n" "${pathexpan}")
# 	return $?
# }
