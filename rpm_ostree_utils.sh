#!/bin/bash

rot.search() {
	rpm-ostree search "${1}" | sort -u | grep -E -v "^="
}

rot.id.booted() {
	rpm-ostree status --json | jq -r '.deployments | to_entries[] | select(.value.booted).key'
}

rot.pl() {
	[[ " $* " =~ ' --help ' ]] && {
		echo -e "Usage: rot_pl [DEPLOYMENT_INDEX]
List packages from a specific deployment in rpm-ostree (default: index 0).
	--lskeys	List top level keys
	--lsdeps	List deployment indexes
	--lsdepsver	-//- with versions";
		return 0;
	}
	[[ " $* " =~ ' --lskeys ' ]] && { rpm-ostree status --json | jq -r 'keys[]'; return 0; }
	[[ " $* " =~ ' --lsdeps ' ]] && { rpm-ostree status --json | jq -r '.deployments | keys[]'; return 0; }
	[[ " $* " =~ ' --lsdepsver ' ]] && { rpm-ostree status --json | jq -r '.deployments | to_entries[] | "\(.key)\t\(.value.version)"'; return 0; }
	local depl="${1:-$(rot_id_booted)}"; [[ ! "$depl" =~ ^[0-9]+$ ]] && { echo -e "Error: Deployment index must be a number" >&2; return 1; }
	local json_data; json_data=$(rpm-ostree status --json) || { echo -e "Error: Failed to get rpm-ostree status" >&2; return 1; }
	local deployment_count; deployment_count=$(echo "$json_data" | jq '.deployments | length')
	[[ "${depl}" -ge "${deployment_count}" ]] && { echo -e "Error: Deployment index ${depl} out of range (total deployments: $deployment_count)" >&2; return 1; }
	echo "$json_data" | jq -r --argjson idx "${depl}" '.deployments[$idx].packages[]?'
}

rot.pl.diff() {
	local depl_old="${1:-1}"; [[ ! "${depl_old}" =~ ^[0-9]+$ ]] && { echo -e "Old Deployment index must be a number (got ${depl_old})"; return 1; }
	local depl_new="${2:-$(rot_id_booted)}"; [[ ! "${depl_new}" =~ ^[0-9]+$ ]] && { echo -e "New Deployment index must be a number (got ${depl_new})"; return 1; }
	diff -u <(rot_pl "${depl_old}") <(rot_pl "${depl_new}") | perl -ne 'print if /^[+-]/'
}

# Clear lists
# of added:
#rot_pl_diff 2 | grep -E "^\+" | tail -n+2 | sed 's/^[-]//g'
# of removed:
#rot_pl_diff 2 | grep -E "^\-" | tail -n+2 | sed 's/^[-]//g'
# Wrap in $(cmd) for a bash array / space separated list
# To reinstall missing:
#rot install --apply-live -y $(rot_pl_diff | grep -E -v "^\+" | tail -n+2 | sed 's/^[-]//g')


