#!/bin/bash

alias rot='rpm-ostree'

alias rot_i='rpm-ostree install --apply-live -y'

rot.search() {
	rpm-ostree search "${1}" | sort -u | grep -E -v "^="
}

rot.id.booted() {
	[[ " $* " =~ ' --help ' ]] && {
		echo -e "Usage: rot.id.booted [OPTIONS]
Get information about the currently booted deployment.
	--version	Show deployment index and version
	--version-only	Show only the version string"
		return 0
	}
	local json_data=$(rpm-ostree status --json) || { echo -e "Error: Failed to get rpm-ostree status" >&2; return 1; }
	local deployments=$(echo "$json_data" | jq '.deployments')
	local booted_deployment_entries=$(echo "$deployments" | jq '. | to_entries[] | select(.value.booted)')
	local booted_index=$(echo "$booted_deployment_entries" | jq -r '.key')
	local booted_version=$(echo "$booted_deployment_entries" | jq -r '.value.version')
	[[ " $* " =~ ' --version-only ' ]] && { echo -e "${booted_version}"; return 0; }
	[[ " $* " =~ ' --version ' ]] && { echo -e "${booted_index}\t${booted_version}"; return 0; }
	echo -e "${booted_index}"
}

rot.pl() {
	[[ " $* " =~ ' --help ' ]] && {
		echo -e "Usage: rot.pl [DEPLOYMENT_INDEX]
List packages from a specific deployment in rpm-ostree (default: index 0).
	--lskeys	List top level keys
	--lsdeps	List deployment indexes
	--lsdepsver	-//- with versions"
		return 0
	}
	local json_data=$(rpm-ostree status --json) || { echo -e "Error: Failed to get rpm-ostree status" >&2; return 1; }
	[[ " $* " =~ ' --lskeys ' ]] && { echo "${json_data}" | jq -r 'keys[]'; return 0; }
	[[ " $* " =~ ' --lsdeps ' ]] && { echo "${json_data}" | jq -r '.deployments | keys[]'; return 0; }
	[[ " $* " =~ ' --lsdepsver ' ]] && { echo "${json_data}" | jq -r '.deployments | to_entries[] | "\(.key)\t\(.value.version)"'; return 0; }
	local depl="${1:-$(rot.id.booted)}"
	[[ ! "$depl" =~ ^[0-9]+$ ]] && { echo -e "Error: Deployment index must be a number" >&2; return 1; }
	local deployment_count=$(echo "$json_data" | jq '.deployments | length')
	[[ "${depl}" -ge "${deployment_count}" ]] && { echo -e "Error: Deployment index ${depl} out of range (total deployments: $deployment_count)" >&2; return 1; }
	echo "$json_data" | jq -r --argjson idx "${depl}" '.deployments[$idx].packages[]?'
}

rot.pl.diff() {
	local depl_old="${1:-1}"
	[[ ! "${depl_old}" =~ ^[0-9]+$ ]] && { echo -e "Old Deployment index must be a number (got ${depl_old})"; return 1; }
	local depl_new="${2:-$(rot.id.booted)}"
	[[ ! "${depl_new}" =~ ^[0-9]+$ ]] && { echo -e "New Deployment index must be a number (got ${depl_new})"; return 1; }
	diff -u <(rot_pl "${depl_old}") <(rot_pl "${depl_new}") | perl -ne 'print if /^[+-]/'
}

rot.pl.diff.add() {
	rot_pl_diff "${1}" | grep -E "^\+" | tail -n+2 | sed 's/^[+-]//g'
}

rot.pl.diff.rem() {
	rot_pl_diff "${1}" | grep -E "^\-" | tail -n+2 | sed 's/^[+-]//g'
}

# Wrap in $(cmd) for a bash array / space separated list
# To reinstall missing:
#rot install --apply-live -y $(rot_pl_diff | grep -E -v "^\+" | tail -n+2 | sed 's/^[-]//g')
