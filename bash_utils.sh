#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

bash.history.ls() {
	HISTTIMEFORMAT="" history "$@" | cut -c 8-
}

bash.ls.git() {
	local showhelp=0
	while (($#)); do
		case "$1" in
		--help | -h) showhelp=1 ;;
		*)
			echo "Error: command accepts no arguments" >&2
			return 1
			;;
		esac
		shift
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]}
			List all dirs, marking git repos and showing 1st line of README.md
			  --help    Show this help
		EOF
		return 0
	}

	local color_QUT='\033[47;30m'
	local color_GIT='\033[40;37m'
	local color_NC='\033[0m'
	local listed_files=""
	local tab_length=0

	local IFSB_previous=$IFS
	IFS=$'\n'

	local items
	items=$(ls --color --group-directories-first -h1A)

	for item in $items; do
		plain_item=$(echo "$item" | sed 's/\x1b\[[0-9;]*m//g')
		display_item="$item"
		git_mark=""
		first_line=""
		if [[ -d "$plain_item" ]]; then
			((tab_length < ${#plain_item})) && tab_length="${#plain_item}"
			[ -d "$plain_item/.git" ] && git_mark="${color_GIT}\xF0\x9F\x8C\xBF${color_NC} "
			[ -f "$plain_item/README.md" ] && first_line=$(awk 'NR==1{print; exit}' "$plain_item/README.md")
			listed_files+="$display_item\t$git_mark${color_QUT}$first_line${color_NC}\n"
		else
			listed_files+="$display_item\n"
		fi
	done

	IFS=$IFSB_previous

	tab_stop=$(tabs -d | awk -F "tabs " 'NR==1{ print $2 }')
	tabs $((tab_length + 1))
	echo -e "$listed_files"
	tabs "$tab_stop"
}

bash.find.mention.roots() {
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
			Usage: ${FUNCNAME[0]} DIR
			Find subdirectories whose name is mentioned in their own files.
		EOF
		return 0
	}
	[[ -z "${1:-}" ]] && {
		echo "Error: directory required" >&2
		return 1
	}
	find "${1}" -mindepth 1 -maxdepth 1 -type d -exec sh -c 'grep -riq -- "$(basename "$(pwd)")" "$1" 2>/dev/null' _ {} \; -print
}

bash.commands() {
	# Prints all loaded aliases, commands & functions
	compgen -c
}

bash.draw_hint() {
	echo -e '\033[47;30m^C\033[0m Interrupt\t\033[47;30m^Z\033[0m Suspend\t\033[47;30m^D\033[0m Close\n\033[47;30m^L\033[0m Clear Screen\t\033[47;30m^S\033[0m Stop Out\t\033[47;30m^Q\033[0m Resume Out\n\033[47;30m^K\033[0m Cut to end\t\033[47;30m^U\033[0m Cut to start\t\033[47;30m^Y\033[0m Paste\n\033[47;30m^P\033[0m Prev cmd\t\033[47;30m^N\033[0m Next cmd\t\033[47;30m^R\033[0m Srch hist\n'
}

export -f bash.history.ls bash.ls.git bash.find.mention.roots bash.commands bash.draw_hint
register_simple_completion "bash.history.ls"
register_simple_completion "bash.ls.git"
register_simple_completion "bash.find.mention.roots"
register_simple_completion "bash.commands"
register_simple_completion "bash.draw_hint"
