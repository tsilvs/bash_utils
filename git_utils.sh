#!/bin/bash

# Takes in a remote address, like
# - git@remote:user/project.git
# - https://remote/user/project.git
# Clones it to a directory, like
# - $(pwd)/user/project
# Using:
# - mkdir -p
# - git -C

#git_clone_to_dir() {
#	local remote_address="${1}"; [[ -z "$remote_address" ]] && { echo "Remote address is required"; return 1; }
#	local project_name=$(basename "$remote_address" .git)
#	local user_name=$(echo "$remote_address" | sed -E 's/.*[:/]([^/]+)\/[^/]+\.git/\1/' | sed -E 's/.*@//')
#	local target_dir="$(pwd)/$user_name/$project_name"
#
#	mkdir -p "$target_dir"
#	git -C "$target_dir" clone "$remote_address" .
#}