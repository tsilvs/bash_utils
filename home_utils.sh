#!/bin/bash

home.tar() {
	local archive_name="backup-home.tar.gz"
	rm "${archive_name}"
	tar -cvpzf \
		"${archive_name}" \
		--exclude="${archive_name}" \
		--exclude='.cache' \
		--exclude='.local' \
		--exclude='.var' \
		--exclude='.thunderbird' \
		--exclude='.mozilla' \
		--exclude='.librewolf' \
		--exclude='.config' \
		--exclude='.nuget' \
		--exclude='.npm' \
		--exclude='.wine' \
		--one-file-system \
		~
}