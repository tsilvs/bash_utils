#!/bin/bash
rpm.pkg.info() {
	local pkg_name="${1:?"Package name is required"}"
	rpm -qi "${pkg_name}"
	return $?
}

rpm.pkg.files() {
	local pkg_name="${1:?"Package name is required"}"
	rpm -ql "${pkg_name}"
	return $?
}

rpm.file.pkg() {
	local filepath="${1:?"File path is required"}"
	rpm -q --whatprovides "${filepath}"
	return $?
}

rpm.cmd.pkg() {
	local command="${1:?"Command is required"}"
	rpm.file.pkg "$(which "${command}")"
	return $?
}