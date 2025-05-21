#!/bin/bash

adb.diff.apps() {
	local device="${1}"; [[ -z "$device" ]] && { echo "Device ID (Serial or IP address) is required"; return 1; }
	local u1="${2:-0}"; [[ ! "$u1" =~ ^[0-9]+$ ]] && { echo "User 1 ID must be a number"; return 1; }
	local u2="${3:-10}"; [[ ! "$u2" =~ ^[0-9]+$ ]] && { echo "User 2 ID must be a number"; return 1; }
	diff -u \
		<(adb -s "${device}" shell cmd package list packages --user "${u1}") \
		<(adb -s "${device}" shell cmd package list packages --user "${u2}") \
		| perl -ne 'print if /^[+-]/' \
		| sed 's/package://g'
}

adb.ifu() {
	local device="${1}"; [[ -z "$device" ]] && { echo "Device ID (Serial or IP address) is required"; return 1; }
	local u="${2:-0}"; [[ ! "$u" =~ ^[0-9]+$ ]] && { echo "User ID must be a number"; return 1; }
	local argnum=2
	shift ${argnum}
	local apps=("$@"); [[ ${#apps[@]} -eq 0 ]] && { echo "At least one app package name is required"; return 1; }
	for app in "${apps[@]}"; do
		echo "Installing ${app} for user ${u} on device ${device}"
		adb -s "${device}" shell cmd package install-existing --user "${u}" "${app}"
	done
}