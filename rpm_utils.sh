#!/bin/bash

rpm.pkg.info() {
	local pkg_name="${1}"; [[ -z "${pkg_name}" ]] && { echo "Package name is required"; return 1; }
	rpm -qi "${pkg_name}"
}

rpm.pkg.files() {
	local pkg_name="${1}"; [[ -z "${pkg_name}" ]] && { echo "Package name is required"; return 1; }
	rpm -ql "${pkg_name}"
}