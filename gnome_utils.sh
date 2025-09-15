#!/usr/bin/env bash

gsettings.ls() {
	for schema in $(gsettings list-schemas | grep -E "^org.gnome" --color=none | sort -u); do gsettings list-recursively $schema; done
	return $?
}

gdm.theme.cursor.set() {
	local argnum=1
	(($# > argnum)) && { echo -e "Command accepts 1 argument"; return 0; }
	local theme_name="${1:?"Theme name is required"}"
	sudo -u gdm dbus-launch gsettings set org.gnome.desktop.interface cursor-theme "${theme_name}"
}