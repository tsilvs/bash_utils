#!/bin/bash

fpl() {
	flatpak list --system --app --columns=origin,application,name,version | tail -n+1 | sort -u
	return $?
}

# fpl.sock() {
# 	local browser=${1:?""}
# 	flatpak override --system --filesystem=xdg-run/app/org.keepassxc.KeePassXC:ro "${browser}"
# 	return $?
# }
