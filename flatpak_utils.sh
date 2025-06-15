#!/bin/bash

fpl() {
	flatpak list --system --app --columns=origin,application,name,version | tail -n+1 | sort -u
}

