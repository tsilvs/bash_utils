#!/bin/bash

gs.ls() {
	for schema in $(gsettings list-schemas | grep -E "^org.gnome" --color=none | sort -u); do gsettings list-recursively $schema; done
	return $?
}