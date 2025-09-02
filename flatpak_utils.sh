#!/bin/bash

fpl() {
	flatpak list --system --app --columns=origin,application,name,version | tail -n+1 | sort -u
	return $?
}

# fpl.fslink() {
# 	local app1=${1:?"Package 1 is required"}
# 	local app2=${2:?"Package 2 is required"}
# 	local scope=${3:-"--system"}
# 	flatpak override "${scope}" --filesystem="xdg-run/app/${app1}:ro" "${app2}"
# 	return $?
# }

# flatpak override --system --filesystem=xdg-run/app/org.keepassxc.KeePassXC:ro io.github.ungoogled_software.ungoogled_chromium
# flatpak override --system --talk-name=org.freedesktop.NativeMessagingProxy io.github.ungoogled_software.ungoogled_chromium
# flatpak override --system --talk-name=org.freedesktop.NativeMessagingProxy org.keepassxc.KeePassXC
# flatpak override --system --filesystem=xdg-run/app/org.keepassxc.KeePassXC/:create io.github.ungoogled_software.ungoogled_chromium