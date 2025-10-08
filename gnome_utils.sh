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
	return $?
}

gnome.ext.sys.ls() {
	ls -1 --color=none --group-directories-first /usr/share/gnome-shell/extensions
	return $?
}

gnome.ext.user.mvsys() {
	local SYSEXT_PREFIX="/var/lib/extensions"
	return $?
}