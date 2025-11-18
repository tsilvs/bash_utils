#!/usr/bin/env bash

sleep.modes.show() {
	cat /sys/power/mem_sleep
	sudo dmesg | grep --color=none -i "acpi" | grep --color=none -i "(supports" | cut -b 16-
	return $?
}

# Sleep-related kernel params
# mem_sleep_default:
# 	deep
# 	suspend-then-hibernate
