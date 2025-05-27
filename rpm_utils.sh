#!/bin/bash

rpm.pkg.info() {
	local pkg_name="${1:?"Package name is required"}"
	rpm -qi "${pkg_name}"
}

rpm.pkg.files() {
	local pkg_name="${1:?"Package name is required"}"
	rpm -ql "${pkg_name}"
}