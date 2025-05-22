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
tree.() {
	tree --dirsfirst "$@"
	return $?
}
rename.() {
	prename "$@"
	return $?
}

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

find_mention_roots() {
	find "${1}" -mindepth 1 -maxdepth 1 -type d -exec sh -c 'grep -riq -- "$(basename "$(pwd)")" "$1" 2>/dev/null' _ {} \; -print
	return $?
}