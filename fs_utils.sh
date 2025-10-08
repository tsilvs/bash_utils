#!/usr/bin/env bash

lsblk.uuid() {
	# set -o errexit
	# set -o pipefail
	# set -o nounset
	# local -r __dirname="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	# local -r __filename="${__dirname}/$(basename "${BASH_SOURCE[0]}")"
	lsblk --output PARTUUID,PARTLABEL,UUID,LABEL,NAME,TYPE,MOUNTPOINTS,SIZE "$@"
	# exit 0
}

dir.monitor() {
	MONITOR_DIR="$1"
	if [[ -z "$MONITOR_DIR" ]]; then
		echo "Usage: $0 /path/to/directory"
		exit 1
	fi

	echo "Monitoring new file creation in $MONITOR_DIR"

	inotifywait -m -e create --format '%w%f' "$MONITOR_DIR" | while read NEWFILE
	do
		# Find processes that have the new file open
		PIDS=$(lsof "$NEWFILE" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)
		if [[ -z "$PIDS" ]]; then
			echo "New file created: $NEWFILE (No process found holding it open yet)"
		else
			for PID in $PIDS; do
				PROC_NAME=$(ps -p $PID -o comm=)
				echo "New file created: $NEWFILE by PID $PID ($PROC_NAME)"
			done
		fi
	done
}

file.monitor() {
	FILE_TO_MONITOR="$1"
	if [[ -z "$FILE_TO_MONITOR" ]]; then
		echo "Usage: $0 /path/to/file"
		exit 1
	fi

	# Start monitoring file creation using auditctl (needs root)
	echo "Adding audit rule for $FILE_TO_MONITOR"
	sudo auditctl -w "$FILE_TO_MONITOR" -p w -k filewatch

	echo "Monitoring file creation/modification events. Press Ctrl+C to stop."

	sudo ausearch -k filewatch --format raw | while read -r line; do
		PID=$(echo "$line" | grep -oP '(pid=\K\d+')
		if [[ -n "$PID" ]]; then
			PROC_NAME=$(ps -p $PID -o comm=)
			echo "File $FILE_TO_MONITOR modified/created by PID $PID ($PROC_NAME)"
		fi
	done
}