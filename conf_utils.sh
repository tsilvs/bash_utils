#!/bin/bash

conf.set() {
	local conf_file="${1:?"Conf file is required"}"
	local key="${2:?"Key is required"}"
	local value="${3:?"Value is required"}"
	[[ ! $(grep -q "^${key}=" "${conf_file}") ]] && { echo "${key}=${value}" >> "${conf_file}"; return 0; }
	sed -i "s/^${key}=.*/${key}=${value}/" "${conf_file}"
}