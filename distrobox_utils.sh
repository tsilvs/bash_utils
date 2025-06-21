#!/bin/bash

# distrobox create --root \
#	--name name \
#	--image transport/image:tag
#	--volume /var/run/docker.sock:/var/run/docker.sock:z
# distrobox enter --root name

# distrobox.export() {
# 	local container
# 	local app_command
# 	local app_bin_path
# 	local export_path="~/.local/bin"
# 	# Ensure `export_path` exists and is writable
# 	sudo mkdir -p "${export_path}"
# 	sudo chown "$(id --user --name)" "${export_path}"
# 	# Append to PATH
# 	# Find the command path inside the container
# 	app_bin_path="$(distrobox enter --root "${container}" -- which "${app_command}")"
# 	# Run `distrobox-export` with the correct path
# 	distrobox enter --root "${container}" -- distrobox-export --bin "${app_bin_path}" --export-path "${export_path}"
# }


