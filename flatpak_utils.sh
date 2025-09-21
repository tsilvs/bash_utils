#!/usr/bin/env bash

flatpak.ls() {
	flatpak list --system --app --columns=application | tail -n+1 | sort -u
	# flatpak list --system --app --columns=origin,application,name,version | tail -n+1 | sort -u
	return $?
}

# fpl.fslink() {
# 	local app1=${1:?"Package 1 is required"}
# 	local app2=${2:?"Package 2 is required"}
# 	local scope=${3:-"--system"}
# 	flatpak override "${scope}" --filesystem="xdg-run/app/${app1}:ro" "${app2}"
# 	return $?
# }

# flatpak override --system --filesystem=xdg-run/app/org.keepassxc.KeePassXC:ro io.github.ungoogled_software.ungoogled_chromium
# flatpak override --system --talk-name=org.freedesktop.NativeMessagingProxy io.github.ungoogled_software.ungoogled_chromium
# flatpak override --system --talk-name=org.freedesktop.NativeMessagingProxy org.keepassxc.KeePassXC
# flatpak override --system --filesystem=xdg-run/app/org.keepassxc.KeePassXC/:create io.github.ungoogled_software.ungoogled_chromium

flatpak.gh.url() {
	local usage
	usage() {
		echo "Usage: ${FUNCNAME[1]} [options] author/repo"
		echo ""
		echo "Options:"
		echo "  -h, --help        Show this help message and exit"
		echo "  -V, --verbose     Enable verbose output"
		echo "  --releasever VER  Specify release version tag (default: latest)"
	}

	local verbose=0
	local releasever="latest"
	local repo=""
	while [[ $# -gt 0 ]]; do
		case $1 in
			-h|--help)
				usage
				return 0
				;;
			-V|--verbose)
				verbose=1
				shift
				;;
			--releasever)
				if [[ -n $2 ]]; then
					releasever=$2
					shift 2
				else
					echo "Error: --releasever requires a version argument"
					return 1
				fi
				;;
			*)
				repo=$1
				shift
				;;
		esac
	done

	if [[ -z $repo ]]; then
		usage
		return 1
	fi

	local arch=$(uname -m)
	case $arch in
		x86_64) arch="x86_64" ;;
		aarch64|arm64) arch="aarch64" ;;
		*) arch="x86_64" ;; # fallback
	esac

	local url
	if [[ $releasever == "latest" ]]; then
		url=$(curl -s "https://api.github.com/repos/$repo/releases/latest" \
			| jq -r --arg arch "$arch" '.assets[] | select(.name | contains($arch)) | .browser_download_url' | head -n1)
	else
		url=$(curl -s "https://api.github.com/repos/$repo/releases/tags/$releasever" \
			| jq -r --arg arch "$arch" '.assets[] | select(.name | contains($arch)) | .browser_download_url' | head -n1)
	fi

	if [[ -z $url ]]; then
		echo "No matching Flatpak found for arch $arch in repo $repo release $releasever"
		return 1
	fi

	(( verbose )) && echo "Downloading from: $url"

	echo "$url"
}

# flatpak.gh.get() {
# 	local file="$1"
# 	shift
# 	if [[ -z $file ]]; then
# 		echo "Usage: ${FUNCNAME[0]} file_path [options] author/repo"
# 		return 1
# 	fi
# 	local url
# 	url=$(flatpak.gh.url "$@") || return 1
# 	curl -L "$url" -o "$file"
# 	echo "Downloaded to $file"
# }