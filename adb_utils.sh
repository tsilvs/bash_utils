#!/bin/bash

adb.users() {
	local device="${1:?"Device ID (Serial or IP address) is required"}"
	adb -s $device shell pm list users
}

alias adb_u='adb.users'

adb.u() {
	adb.users $@
}

# adb.pair () {
# }

adb.diff.apps() {
	# TODO:
	# + add options to filter out:
	# 	+ only matching
	# 	+ only added
	# 	+ only removed
	local device="${1:?"Device ID (Serial or IP address) is required"}"
	local u1="${2:-0}"; [[ ! "$u1" =~ ^[0-9]+$ ]] && { echo "User 1 ID must be a number"; return 1; }
	local u2="${3:-10}"; [[ ! "$u2" =~ ^[0-9]+$ ]] && { echo "User 2 ID must be a number"; return 1; }
	diff -u \
		<(adb -s "${device}" shell cmd package list packages --user "${u1}") \
		<(adb -s "${device}" shell cmd package list packages --user "${u2}") \
		| perl -ne 'print if /^[+-]/' \
		| sed 's/package://g'
}

adb.ifu() {
	# TODO:
	# + Accept multiple
	# 	+ Users
	# 	+ Apps - done
	# + Accept flags
	# 	+ for all users
	local device="${1:?"Device ID (Serial or IP address) is required"}"
	local u="${2:-0}"; [[ ! "$u" =~ ^[0-9]+$ ]] && { echo "User ID must be a number"; return 1; }
	local argnum=2
	shift ${argnum}
	# for user in users
	local apps=("$@"); [[ ${#apps[@]} -eq 0 ]] && { echo "At least one app package name is required"; return 1; }
	for app in "${apps[@]}"; do
		echo "Installing ${app} for user ${u} on device ${device}"
		adb -s "${device}" shell cmd package install-existing --user "${u}" "${app}"
	done
}

adb.ufu() {
	# TODO:
	# + Accept multiple
	# 	+ Users
	# 	+ Apps - done
	# + Accept flags
	# 	+ for all users
	local device="${1:?"Device ID (Serial or IP address) is required"}"
	local u="${2:-0}"; [[ ! "$u" =~ ^[0-9]+$ ]] && { echo "User ID must be a number"; return 1; }
	local argnum=2
	shift ${argnum}
	# for user in users
	local apps=("$@"); [[ ${#apps[@]} -eq 0 ]] && { echo "At least one app package name is required"; return 1; }
	for app in "${apps[@]}"; do
		echo "Uninstalling ${app} for user ${u} on device ${device}"
		adb -s "${device}" shell cmd package uninstall --user "${u}" "${app}"
	done
}

# jq '.[]["removal"]' --raw-output 0x192/universal-android-debloater/resources/assets/uad_lists.json | sort -u
# adb.ufu $device $uid $(jq '.[] | select(.removal=="Recommended") | select(.id | match(".*google.*")) | .id' --raw-output 0x192/universal-android-debloater/resources/assets/uad_lists.json)

