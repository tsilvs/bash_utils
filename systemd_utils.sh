#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

systemd.locate() {
	local showhelp=0
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} UNIT
			Show location of a systemd unit file.
		EOF
		return 0
	}
	[[ -z "${1:-}" ]] && {
		echo "Error: unit name required" >&2
		return 1
	}
	systemctl cat "$1" 2>/dev/null | head -1
}

systemd.ls.enabled() {
	local showhelp=0
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]}
			List enabled systemd units.
		EOF
		return 0
	}
	systemctl list-unit-files --state=enabled
}

systemd.ls.active() {
	local showhelp=0
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]}
			List active systemd units.
		EOF
		return 0
	}
	systemctl list-units --state=active
}

systemd.log() {
	local showhelp=0 lines=50
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		-n)
			lines="$2"
			shift 2
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [-n LINES] UNIT
			Show recent journal logs for a unit.
		EOF
		return 0
	}
	[[ -z "${1:-}" ]] && {
		echo "Error: unit name required" >&2
		return 1
	}
	journalctl -u "$1" -n "$lines" --no-pager
}

export -f systemd.locate systemd.ls.enabled systemd.ls.active systemd.log
register_simple_completion "systemd.locate"
register_simple_completion "systemd.ls.enabled"
register_simple_completion "systemd.ls.active"
register_simple_completion "systemd.log" "-n"
