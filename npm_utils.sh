#!/usr/bin/env bash

npm.search() {
	local query="${@}"
	local template="\(.name)\t\(.version)"
	npm search \
		--no-description \
		--json "${query}" \
		| \
		jq --raw-output ".[] | \"${template}\"" \
		| \
		sort \
			--ignore-case \
			--ignore-leading-blanks \
			--version-sort
}

alias npm_s="npm.search"