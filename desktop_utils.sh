#!/usr/bin/env bash

desktop.ls.comm() {
	comm -12 <(ls -1 /usr/share/applications/) <(ls -1 ~/.local/share/applications)
	return $?
}

desktop.assoc.refresh() {
	update-desktop-database ~/.local/share/applications/
	return $?
}

desktop.mime.refresh() {
	update-mime-database ~/.local/share/mime/
	return $?
}
