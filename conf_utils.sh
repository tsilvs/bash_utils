#!/bin/bash

conf.set() {
	local conf_file="${1}"; [[ -z "${conf_file}" ]] && { echo "Conf file is required"; return 1; }
	local key="${2}"; [[ -z "${key}" ]] && { echo "Key is required"; return 1; }
	local value="${3}"; [[ -z "${value}" ]] && { echo "Value is required"; return 1; }
	[[ ! $(grep -q "^${key}=" "${conf_file}") ]] && { echo "${key}=${value}" >> "${conf_file}"; return 0; }
	sed -i "s/^${key}=.*/${key}=${value}/" "${conf_file}"
}