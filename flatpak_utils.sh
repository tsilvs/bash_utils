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
	return $?
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

# flatpak list --app --columns=application | xargs -I{} flatpak info --show-metadata {} 2>/dev/null

flatpak.alias.gen() {
	local app="" scope="--system" cmd=""
	while [[ $# -gt 0 ]]; do
		case $1 in
			-u|--user) scope="--user"; shift ;;
			-s|--system) scope="--system"; shift ;;
			--command=*) cmd="${1#*=}"; shift ;;
			*) app="$1"; shift ;;
		esac
	done
	
	[[ -z "$app" ]] && { echo "Error: app required" >&2; return 1; }
	
	if [[ -z "$cmd" ]]; then
		cmd=$(flatpak info --show-metadata "$app" $scope 2>/dev/null | grep '^command=' | cut -d= -f2)
		[[ -z "$cmd" ]] && { echo "Error: no command found for $app" >&2; return 1; }
	fi
	
	echo "$cmd() { flatpak run $scope --command=$cmd --file-forwarding $app \"\$@\"; return \$?; }"
}

flatpak.alias.gen.all() {
	local scope="" group_folders=false
	while [[ $# -gt 0 ]]; do
		case $1 in
			-u|--user) scope="--user"; shift ;;
			-s|--system) scope="--system"; shift ;;
			-g|--group-by-folders) group_folders=true; shift ;;
			*) shift ;;
		esac
	done
	
	if [[ "$group_folders" == true ]]; then
		local folder_map=$(mktemp)
		local folder="" folder_order=0 apps_buffer=""
		
		while IFS= read -r line; do
			if [[ "$line" == "["*"]"* && "$line" == *"["*"-"* ]]; then
				((folder_order++))
				folder=""
				apps_buffer=""
			elif [[ "$line" == "apps="* ]]; then
				apps_buffer=$(echo "$line" | cut -d= -f2 | tr -d "[]'\" ")
			elif [[ "$line" == "name="* ]]; then
				folder=$(echo "$line" | cut -d= -f2 | tr -d "\"'")
				if [[ -n "$apps_buffer" && -n "$folder" ]]; then
					IFS=, read -ra apps <<< "$apps_buffer"
					for app in "${apps[@]}"; do
						app="${app%.desktop}"
						[[ -n "$app" ]] && printf "%03d:%s:%s\n" "$folder_order" "$app" "$folder" >> "$folder_map"
					done
					apps_buffer=""
				fi
			fi
		done < <(dconf dump /org/gnome/desktop/app-folders/folders/)
		
		local output=$(mktemp)
		flatpak list --app --columns=application $scope | while read -r app; do
			local entry=$(grep ":${app}:" "$folder_map" | head -1)
			local func=$(flatpak.alias.gen $scope "$app")
			if [[ -n "$entry" ]]; then
				echo "$entry|$func" >> "$output"
			else
				echo "999:!not found:!not found|$func" >> "$output"
			fi
		done
		
		sort -t'|' -k1,1 "$output" | awk -F'|' 'BEGIN{prev=""} {split($1,a,":"); folder=a[3]; if(folder!=prev){if(prev!="")print ""; print "# "folder; prev=folder} print $2}'
		rm -f "$output" "$folder_map"
	else
		flatpak list --app --columns=application $scope | while read -r app; do
			flatpak.alias.gen $scope "$app"
		done
	fi
}

