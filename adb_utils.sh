#!/usr/bin/env bash

# SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

adb.users() {
	[[ "$1" =~ ^(-h|--help)$ ]] && { echo "Usage: ${FUNCNAME[0]} <device_id>"; return 0; }
	local device="${1:?"Device ID (Serial or IP address) is required"}"
	adb -s "$device" shell pm list users | tail -n +2 | awk -F "[{:}]" '{print $2}'
}

adb.app.ls() {
	local device="" user=0
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				cat <<-EOF
				Usage: ${FUNCNAME[0]} <device_id> [options]
				Options:
				  -u|--user <id>  User ID (default: 0)
				EOF
				return 0
				;;
			-u|--user) user="$2"; shift 2 ;;
			*) [[ -z "$device" ]] && { device="$1"; shift; } || shift ;;
		esac
	done
	
	[[ -z "$device" ]] && { echo "Device ID required"; return 1; }
	[[ ! "$user" =~ ^[0-9]+$ ]] && { echo "User ID must be a number"; return 1; }
	
	adb -s "${device}" shell cmd package list packages --user "${user}" | sed 's/^package://g' | sort
}

adb.apps.diff() {
	local device="" u1=0 u2=10 filter=""
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				cat <<-EOF
				Usage: ${FUNCNAME[0]} <device_id> [options]
				Options:
				  -u1 <id>      First user ID (default: 0)
				  -u2 <id>      Second user ID (default: 10)
				  -m|--matching Only show matching packages
				  -a|--added    Only show packages added in u2
				  -r|--removed  Only show packages removed from u2
				EOF
				return 0
				;;
			-u1) u1="$2"; shift 2 ;;
			-u2) u2="$2"; shift 2 ;;
			-m|--matching) filter="matching"; shift ;;
			-a|--added) filter="added"; shift ;;
			-r|--removed) filter="removed"; shift ;;
			*) [[ -z "$device" ]] && { device="$1"; shift; } || shift ;;
		esac
	done
	
	[[ -z "$device" ]] && { echo "Device ID required"; return 1; }
	[[ ! "$u1" =~ ^[0-9]+$ ]] && { echo "User 1 ID must be a number"; return 1; }
	[[ ! "$u2" =~ ^[0-9]+$ ]] && { echo "User 2 ID must be a number"; return 1; }
	
	local diff_output
	diff_output=$(diff -u \
		<(adb.app.ls "${device}" -u "${u1}") \
		<(adb.app.ls "${device}" -u "${u2}"))

	case "$filter" in
		matching) echo "$diff_output" | grep -v '^[+-]' ;;
		added) echo "$diff_output" | grep '^+' | grep -v '^+++' | sed 's/^+//' ;;
		removed) echo "$diff_output" | grep '^-' | grep -v '^---' | sed 's/^-//' ;;
		*) echo "$diff_output" | perl -ne 'print if /^[+-]/' | sed 's/^[+-]//' ;;
	esac
}

adb.app.install() {
	local device="" users=() apps=() all_users=false
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				cat <<-EOF
				Usage: ${FUNCNAME[0]} <device_id> [options] <package...>
				Options:
				  -u|--user <id>  User ID (repeatable)
				  -a|--all-users  Install for all users
				EOF
				return 0
				;;
			-u|--user) users+=("$2"); shift 2 ;;
			-a|--all-users) all_users=true; shift ;;
			*) [[ -z "$device" ]] && { device="$1"; shift; } || { apps+=("$1"); shift; } ;;
		esac
	done
	
	[[ -z "$device" ]] && { echo "Device ID required"; return 1; }
	[[ ${#apps[@]} -eq 0 ]] && { echo "At least one package required"; return 1; }
	
	$all_users && users=($(adb.users "${device}"))
	[[ ${#users[@]} -eq 0 ]] && { echo "User ID required"; return 1; }
	
	for u in "${users[@]}"; do
		[[ ! "$u" =~ ^[0-9]+$ ]] && { echo "User ID must be a number: $u"; return 1; }
		for app in "${apps[@]}"; do
			echo "Installing ${app} for user ${u} on device ${device}"
			adb -s "${device}" shell cmd package install-existing --user "${u}" "${app}"
		done
	done
}

adb.app.uninstall() {
	local device="" users=() apps=() all_users=false
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				cat <<-EOF
				Usage: ${FUNCNAME[0]} <device_id> [options] <package...>
				Options:
				  -u|--user <id>  User ID (repeatable)
				  -a|--all-users  Uninstall for all users
				EOF
				return 0
				;;
			-u|--user) users+=("$2"); shift 2 ;;
			-a|--all-users) all_users=true; shift ;;
			*) [[ -z "$device" ]] && { device="$1"; shift; } || { apps+=("$1"); shift; } ;;
		esac
	done
	
	[[ -z "$device" ]] && { echo "Device ID required"; return 1; }
	[[ ${#apps[@]} -eq 0 ]] && { echo "At least one package required"; return 1; }
	
	$all_users && users=($(adb.users "${device}"))
	[[ ${#users[@]} -eq 0 ]] && { echo "User ID required"; return 1; }
	
	for u in "${users[@]}"; do
		[[ ! "$u" =~ ^[0-9]+$ ]] && { echo "User ID must be a number: $u"; return 1; }
		for app in "${apps[@]}"; do
			echo "Uninstalling ${app} for user ${u} on device ${device}"
			adb -s "${device}" shell cmd package uninstall --user "${u}" "${app}"
		done
	done
}

adb.app.in() {
	adb.app.install "$@"
	return $?
}

adb.app.un() {
	adb.app.uninstall "$@"
	return $?
}

export -f adb.users adb.apps.diff adb.app.install adb.app.uninstall adb.app.in adb.app.un adb.app.ls
