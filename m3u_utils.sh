#!/bin/bash

jq.my() {
	local json="$1"
	local prop="$2"
	echo "$json" | jq -r "$prop"
}

m3u.gen() {
	local lang="en"
	local timeout='10000'
	# Takes "$NAUTILUS_SCRIPT_CURRENT_URI"
	local uri="$NAUTILUS_SCRIPT_CURRENT_URI"
	local i18n='
	{
		"en": {
			"succ": {
				"summ": "File Generated",
				"body": "Playlist has been created successfully."
			},
			"fail": {
				"summ": "Error",
				"body": "Playlist making failed. No media files found."
			},
			"open": "Open File",
			"del": "Delete File"
		}
	}
	'
	
	local types=( "wav" "wv" "flac" "ogg" "mp3" "mp4" "avi" "mkv" "m4a")
	
	local dirpath="${uri#file://}"
	dirpath="${dirpath//%20/ }"
	local dirname="${dirpath##*/}"
	
	local playlist_file="$dirpath/$dirname-Full.m3u"
	echo "#EXTM3U" > "$playlist_file"

	local find_cmd="find \"$dirpath\" -type f \("
	for i in "${!types[@]}"; do
		[[ $i -gt 0 ]] && find_cmd+=" -o"
		find_cmd+=" -iname \"*.${types[i]}\""
	done
	find_cmd+=" \)"

	local file_count=0
	local found_files=""
	while read -r file; do
		rel_path="${file#$dirpath/}"
		found_files+="$rel_path\n" 
		((file_count++))
	done < <(eval "$find_cmd")

	echo -e $found_files | sort >> "$playlist_file"
	
	if [ $file_count -gt 0 ]; then
		act=$(
			notify-send \
				"$(jq.my "$i18n" ".$lang.succ.summ")" \
				"$(jq.my "$i18n" ".$lang.succ.body")" \
				-A "open=$(jq.my "$i18n" ".$lang.open")" \
				-A "del=$(jq.my "$i18n" ".$lang.del")" \
				--wait \
				-t $timeout
		)
		case "$act" in
			"open") xdg-open "$playlist_file" ;;
			"del") 
				if [ -f "$playlist_file" ]; then
					rm "$playlist_file"
				fi
				;;
		esac
	else
		notify-send \
			"$(jq.my "$i18n" ".$lang.fail.summ")" \
			"$(jq.my "$i18n" ".$lang.fail.body")"
		[ -f "$playlist_file" ] && rm "$playlist_file"
	fi
	return 0
}

main "$@"