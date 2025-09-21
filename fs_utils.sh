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