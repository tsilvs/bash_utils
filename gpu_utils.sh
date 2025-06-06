#!/bin/bash

vram() {
	lspci -D \
	| grep -i -E "display|vga" \
	| awk '{ print $1 }' \
	| xargs -I{} bash -c '
		bytes=$(cat /sys/bus/pci/devices/{}/mem_info_vram_total);
		gb=$(echo "scale=2; $bytes/1073741824" | bc);
		echo "{}: $gb GB"
	'
}