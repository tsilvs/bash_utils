#!/bin/bash

#alias ls='ls --color --group-directories-first'
#alias lsd='lsd -1 -A -G -X --color always --group-dirs first -l -g'
#alias eza='eza -1AlF --color=always --icons=always --group-directories-first --smart-group --git-repos'
#alias md='mkdir'
#alias tree='tree --dirsfirst'
#alias rename='prename'

ls.() {
	ls --color --group-directories-first "$@"
	return $?
}

lsd.() {
	lsd -1 -A -G -X --color always --group-dirs first -l -g "$@"
	return $?
}

eza.() {
	eza -1AlF --color=always --icons=always --group-directories-first --smart-group --git-repos "$@"
	return $?
}

md.() {
	mkdir "$@"
	return $?
}

rename.() {
	prename "$@"
	return $?
}

# mvall() {
# 	local match="${1}"
# 	local ext="${2}"
# 	for file in $match; do mv "$file" "${file%.}.${ext}"; done
# }

ls.git() {
	[[ " $* " =~ ' --help ' ]] && {
		echo -e "Usage: ls.git
Lists all dirs, marking git repos and showing 1st line of README.md
	--help	Displays this help message"
		return 0
	}
	(($# > 0)) && {
		echo -e "Command accepts no arguments"
		return 0
	}
	local color_QUT='\033[47;30m'
	local color_GIT='\033[40;37m'
	local color_NC='\033[0m'
	local listed_files=""
	local tab_length=0

	local IFSB_previous=$IFS
	IFS=$'\n'

	local items=$(ls --color --group-directories-first -h1A)

	for item in $items; do
		plain_item=$(echo $item | sed 's/\x1b\[[0-9;]*m//g')
		display_item="$item"
		git_mark=""
		first_line=""
		if [[ -d "$plain_item" ]]; then
			(( tab_length < "${#plain_item}" )) && tab_length="${#plain_item}"
			[ -d "$plain_item/.git" ] && git_mark="${color_GIT}\xF0\x9F\x8C\xBF${color_NC} "
			[ -f "$plain_item/README.md" ] && first_line=$(awk 'NR==1{print; exit}' "$plain_item/README.md")
			listed_files+="$display_item\t$git_mark${color_QUT}$first_line${color_NC}\n"
		else
			listed_files+="$display_item\n"
		fi
	done

	IFS=$IFSB_previous

	tab_stop=$(tabs -d | awk -F "tabs " 'NR==1{ print $2 }')
	tabs $(($tab_length + 1))
	echo -e "$listed_files"
	tabs $tab_stop
}

find.mention.roots() {
	find "${1}" -mindepth 1 -maxdepth 1 -type d -exec sh -c 'grep -riq -- "$(basename "$(pwd)")" "$1" 2>/dev/null' _ {} \; -print
	return $?
}

commands() {
# Prints all loaded aliases, commands & functions
	compgen -c

# compgen options
#	A: action
#	o: option
#	C: command
#	F: function

# Patterns
#	G: globpat
#	P: prefix
#	S: suffix
#	X: filterpat
#	W: wordlist

# Users
#	g: groups
#	u: user names

# Files
#	d: directories
#	f: files

# Built-in
#	b: shell builtins
#	k: shell reserved words

# Variables
#	e: exported shell variables
#	v: shell variables

# Background processes
#	j: jobs
#	s: services

# Commands
#	a: aliases
#	c: all commands (aliases, builtins, functions, executables)
}

draw_hint () {
	echo -e '\033[47;30m^C\033[0m Interrupt\t\033[47;30m^Z\033[0m Suspend\t\033[47;30m^D\033[0m Close\n\033[47;30m^L\033[0m Clear Screen\t\033[47;30m^S\033[0m Stop Out\t\033[47;30m^Q\033[0m Resume Out\n\033[47;30m^K\033[0m Cut to end\t\033[47;30m^U\033[0m Cut to start\t\033[47;30m^Y\033[0m Paste\n\033[47;30m^P\033[0m Prev cmd\t\033[47;30m^N\033[0m Next cmd\t\033[47;30m^R\033[0m Srch hist\n'
}