#!/bin/bash

af.flat.template() {
	local command="${1:?"Command is required."}"
	local package="${2:?"Package is required."}"
	echo -e "${command}(){\n\tflatpak run --command=\"${command}\" --file-forwarding ${package} \"\$@\"\n\treturn \$?\n}"
	return $?
}

keepassxc-cli() {
	flatpak run --command="keepassxc-cli" --file-forwarding org.keepassxc.KeePassXC "$@"
	return $?
}

codium() {
	flatpak run --command=com.vscodium.codium --file-forwarding com.vscodium.codium "$@"
	return $?
}

code() {
	codium "$@"
	return $?
}

npm() {
	pnpm "$@"
	return $?
}

# pgrep.() {
# 	local pipe # TODO: Accept pipe stdin
# 	local file # TODO: Accept file path
# 	local regex="${1:?"Regex required."}"
# 	perl -ne "print if /${regex}/"
# 	return $?
# }