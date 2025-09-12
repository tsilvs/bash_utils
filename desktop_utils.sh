#!/bin/bash

desktop.ls.comm() {
	comm -12 <(ls -1 /usr/share/applications/) <(ls -1 ~/.local/share/applications)
}