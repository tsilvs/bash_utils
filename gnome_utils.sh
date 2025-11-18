#!/usr/bin/env bash

gsettings.ls() {
	for schema in $(gsettings list-schemas | grep -E "^org.gnome" --color=none | sort -u); do gsettings list-recursively $schema; done
	return $?
}

gdm.theme.cursor.set() {
	local argnum=1
	(($# > argnum)) && { echo -e "Command accepts 1 argument"; return 0; }
	local theme_name="${1:?"Theme name is required"}"
	sudo -u gdm dbus-launch gsettings set org.gnome.desktop.interface cursor-theme "${theme_name}" 2>/dev/null
	return $?
}

# gdm.theme.cursor.set "breeze_cursors"

# gnome.ext.fs.sys.ls() {
# 	# Same as `gnome-extensions list --system`
# 	# Better to use `gnome-extensions list --system --active`
# 	ls -1 --color=none --group-directories-first /usr/share/gnome-shell/extensions
# 	return $?
# }

gnome.ext.sys.ls() {
	gnome-extensions list --system --active
	return $?
}

gnome.ext.usr.ls() {
	gnome-extensions list --user --active
	return $?
}

# gnome.ext.user.mvsys() {
# 	local SYSEXT_PREFIX="/var/lib/extensions"
# 	return $?
# }

export -f gsettings.ls
export -f gdm.theme.cursor.set
export -f gnome.ext.sys.ls
export -f gnome.ext.usr.ls
# export -f gnome.ext.user.mvsys

# if there is org.gnome.Shell.Extensions.GSConnect

if gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.NameHasOwner "org.gnome.Shell.Extensions.GSConnect" | grep -q true; then

# echo "org.gnome.Shell.Extensions.GSConnect exists and active"

gnome.ext.gsconnect.dev.refresh() {
	local extId="org.gnome.Shell.Extensions.GSConnect"
	local fdp="org.freedesktop.DBus"
	local objPath="/org/gnome/Shell/Extensions/GSConnect"
	
	echo "Refreshing GSConnect devices..."
	
	# Try to activate refresh action on main object
	gdbus call --session \
		--dest "${extId}" \
		--object-path "${objPath}" \
		--method org.gtk.Actions.Activate \
		"refresh" "[]" "{}" >/dev/null 2>&1
	
	# if [ $? -ne 0 ]; then
	# 	# Alternative: try to activate the application which often triggers a refresh
	# 	gdbus call --session \
	# 		--dest "${extId}" \
	# 		--object-path "${objPath}" \
	# 		--method org.gtk.Application.Activate \
	# 		"{}" >/dev/null 2>&1
	# fi

	return $?
}

gnome.ext.gsconnect.dev.cache.clear() {
	local extId="org.gnome.Shell.Extensions.GSConnect"
	local fdp="org.freedesktop.DBus"
	local objPath="/org/gnome/Shell/Extensions/GSConnect"
	# Get all managed objects (devices)
	local managed_objects=$(gdbus call --session \
		--dest "${extId}" \
		--object-path ${objPath} \
		--method ${fdp}.ObjectManager.GetManagedObjects)
	
	# Extract device paths from the output
	local device_paths=$(echo "$managed_objects" | grep -oP "${objPath}/Device/[a-f0-9_]+")
	
	if [ -z "$device_paths" ]; then
		echo "No devices found"
		return 1
	fi
	
	echo "Clearing cache for all devices..."
	
	# Send clear cache action to each device
	for device_path in $device_paths; do
		local device_id=$(basename "$device_path")
		
		# Get device name
		local device_name="$(gdbus call --session \
			--dest "${extId}" \
			--object-path "$device_path" \
			--method ${fdp}.Properties.Get \
			"${extId}.Device" Name 2>/dev/null \
			| perl -n -e "print \$1 if /\(<\'(.*)\'\>/")"
		
		# List available actions for this device
		local actions=$(gdbus call --session \
			--dest "${extId}" \
			--object-path "$device_path" \
			--method org.gtk.Actions.List 2>/dev/null)
		
		# Check if clearCache action exists
		# if echo "$actions" | grep -q "clearCache"; then
		echo "Clearing cache for: ${device_name:-$device_id}"
		
	# Activate the clearCache action (adjust action name based on List output)
		gdbus call --session \
			--dest "${extId}" \
			--object-path "$device_path" \
			--method org.gtk.Actions.Activate \
			"clearCache" "[]" "{}" >/dev/null 2>&1
		
		if [ $? -eq 0 ]; then
			echo "	✓ Cache cleared successfully"
		else
			echo "	✗ Failed to clear cache"
		fi
		# else
		# 	echo "Device ${device_id}: clearCache action not available"
		# 	echo "	Available actions: $actions"
		# fi
	done
	
	# Refresh devices
	gnome.ext.gsconnect.dev.refresh
	
	echo "Done!"
}

export -f gnome.ext.gsconnect.dev.refresh
export -f gnome.ext.gsconnect.dev.cache.clear

fi
