#!/bin/bash

secret.luks.pass() {
	local devuuid="${1:?"Device UUID is required. Try lsblk."}"
	secret-tool lookup xdg:schema org.gnome.GVfs.Luks.Password gvfs-luks-uuid "${devuuid}"
	return $?
}

# secret.ls() {
# 	secret-tool "$@" 
# 	return $?
# }