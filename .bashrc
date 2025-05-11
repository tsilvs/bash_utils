#!/bin/bash

## Utility Functions

draw_hint() {
	echo -e '\033[47;30m^C\033[0m Interrupt\t\033[47;30m^Z\033[0m Suspend\t\033[47;30m^D\033[0m Close\n\033[47;30m^L\033[0m Clear Screen\t\033[47;30m^S\033[0m Stop Out\t\033[47;30m^Q\033[0m Resume Out\n\033[47;30m^K\033[0m Cut to end\t\033[47;30m^U\033[0m Cut to start\t\033[47;30m^Y\033[0m Paste\n\033[47;30m^P\033[0m Prev cmd\t\033[47;30m^N\033[0m Next cmd\t\033[47;30m^R\033[0m Srch hist\n'
}

find_mention_roots() {
	find "$1" -mindepth 1 -maxdepth 1 -type d -exec sh -c 'grep -riq -- "$(basename "$(pwd)")" "$1" 2>/dev/null' _ {} \; -print
}

rot_search() {
	rpm-ostree search "$1" | sort -u | grep -E -v "^="
}

## Aliases

### Commands

alias rot='rpm-ostree'
alias rotpl='rot status -b --json | jq -r ''.deployments[0].packages[]'''
alias clear='clear; draw_hint'
alias md='mkdir'
alias ls='ls --color --group-directories-first'
alias tree='tree --dirsfirst'
alias neofetch='fastfetch'
alias fetch='fastfetch'
alias lsd='lsd -1 -A -G -X --color always --group-dirs first -l -g'
alias eza='eza -1AlF --color=always --icons=always --group-directories-first --smart-group --git-repos'
alias rename='prename'
alias gsls='for schema in $(gsettings list-schemas | grep -E "^org.gnome" --color=none | sort -u); do gsettings list-recursively $schema; done'

## Init calls

[ "$(tty)" != "$SSH_TTY" ] && [ "$(whoami)" != "git" ] && draw_hint