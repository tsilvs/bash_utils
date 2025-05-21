#!/bin/bash

# Imports

. ~/.sh/rpm_ostree_utils.sh
. ~/.sh/bash_utils.sh
. ~/.sh/perl_utils.sh
. ~/.sh/git_utils.sh
. ~/.sh/adb_utils.sh
. ~/.sh/podman_utils.sh

# Utility Functions

draw_hint() {
	echo -e '\033[47;30m^C\033[0m Interrupt\t\033[47;30m^Z\033[0m Suspend\t\033[47;30m^D\033[0m Close
\033[47;30m^L\033[0m Clear Screen\t\033[47;30m^S\033[0m Stop Out\t\033[47;30m^Q\033[0m Resume Out
\033[47;30m^K\033[0m Cut to end\t\033[47;30m^U\033[0m Cut to start\t\033[47;30m^Y\033[0m Paste
\033[47;30m^P\033[0m Prev cmd\t\033[47;30m^N\033[0m Next cmd\t\033[47;30m^R\033[0m Srch hist\n'
}

# Aliases

## Commands

alias rot='rpm-ostree'
#alias rotpl='rot status -b --json | jq -r ''.deployments[0].packages[]'''
alias clear='clear; draw_hint'
alias neofetch='fastfetch'
alias fetch='fastfetch'
alias gsls='for schema in $(gsettings list-schemas | grep -E "^org.gnome" --color=none | sort -u); do gsettings list-recursively $schema; done'
alias code='codium'

# Init calls

[ "$(tty)" != "$SSH_TTY" ] && [ "$(whoami)" != "git" ] && draw_hint