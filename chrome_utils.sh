#!/bin/bash

#chrome.search.keywords.merge() {
#	src_db="$1"
#	dst_db="$2"
#	tmpfile=$(mktemp)
#
#	sqlite3 -csv "$src_db" "SELECT keyword, url, short_name FROM keywords;" >"$tmpfile.src"
#	sqlite3 -csv "$dst_db" "SELECT keyword, url, short_name FROM keywords;" >"$tmpfile.dst"
#
#	cat "$tmpfile.src" "$tmpfile.dst" | sort | uniq >"$tmpfile.merged"
#
#	sqlite3 "$dst_db" "DELETE FROM keywords;"
#	while IFS=, read -r keyword url short_name; do
#		sqlite3 "$dst_db" \
#			"INSERT INTO keywords (keyword, url, short_name) VALUES ('$keyword', '$url', '$short_name');"
#	done <"$tmpfile.merged"
#
#	rm -f "$tmpfile"*
#}
