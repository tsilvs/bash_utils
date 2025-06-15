#!/bin/bash

alias rot='rpm-ostree'

alias rot_i='rpm-ostree install --idempotent --apply-live --assumeyes'
alias rot_u='rpm-ostree uninstall --idempotent --assumeyes'

rot.repos.list() {
	[[ " $* " =~ ' --help ' ]] && {
		echo -e "Usage: ${FUNCNAME[0]} [OPTIONS] [DEPLOYMENT_INDEX]
List repos in a deployment (default index: 0).
	--help	Show this help
"
		return 0
	}
	local json_data=$(rpm-ostree status --json) || { echo -e "Error: Failed to get rpm-ostree status" >&2; return 1; }
	local depl="${1:-$(rot.id.booted)}"
	[[ ! "${depl}" =~ ^[0-9]+$ ]] && { echo -e "Error: Deployment index must be a number" >&2; return 1; }
	local deployment_count=$(echo "$json_data" | jq '.deployments | length')
	[[ "${depl}" -ge "${deployment_count}" ]] && { echo -e "Error: Deployment index ${depl} out of range (total: ${deployment_count})" >&2; return 1; }
	local json_data_depl=$(echo "$json_data" | jq --argjson idx "${depl}" '.deployments[$idx]')
	local repos=$(echo "${json_data_depl}" | jq --raw-output '.["layered-commit-meta"].["rpmostree.rpmmd-repos"][].["id"]' | sort -u)
	echo "${repos}"
}

#rot.repo.url() {
#
#}

rot.search() {
	rpm-ostree search "${1}" | sort -u | grep -E -v "^="
}

rot.id.booted() {
	[[ " $* " =~ ' --help ' ]] && {
		echo -e "Usage: ${FUNCNAME[0]} [OPTIONS]
Get information about the currently booted deployment.
	--version	Show deployment index and version
	--version-only	Show only the version string"
		return 0
	}
	local json_data=$(rpm-ostree status --json) || { echo -e "Error: Failed to get rpm-ostree status" >&2; return 1; }
	local deployments=$(echo "$json_data" | jq '.deployments')
	local booted_deployment_entries=$(echo "$deployments" | jq '. | to_entries[] | select(.value.booted)')
	local booted_index=$(echo "$booted_deployment_entries" | jq --raw-output '.key')
	local booted_version=$(echo "$booted_deployment_entries" | jq --raw-output '.value.version')
	[[ " $* " =~ ' --version-only ' ]] && { echo -e "${booted_version}"; return 0; }
	[[ " $* " =~ ' --version ' ]] && { echo -e "${booted_index}\t${booted_version}"; return 0; }
	echo -e "${booted_index}"
}

rot.pl() {
	[[ " $* " =~ ' --help ' ]] && {
		echo -e "Usage: ${FUNCNAME[0]} [OPTIONS] [DEPLOYMENT_INDEX]
List packages from a specific deployment in rpm-ostree (default: index 0).
	--lskeys	List top level keys
	--lsdeps	List deployment indexes
	--lsdepsver	List deployment indexes with versions
	--ulo	User layered only
	--all	All packages
	--help	Show this help
"
#	--blo	Base layer only
		return 0
	}
	local json_data=$(rpm-ostree status --json) || { echo -e "Error: Failed to get rpm-ostree status" >&2; return 1; }
	[[ " $* " =~ ' --lskeys ' ]] && { shift 1; echo "${json_data}" | jq --raw-output 'keys[]'; return 0; }
	[[ " $* " =~ ' --lsdeps ' ]] && { shift 1; echo "${json_data}" | jq --raw-output '.deployments | keys[]'; return 0; }
	[[ " $* " =~ ' --lsdepsver ' ]] && { shift 1; echo "${json_data}" | jq --raw-output '.deployments | to_entries[] | "\(.key)\t\(.value.version)"'; return 0; }
	local opt_ulo=0
	local opt_all=0
	[[ " $* " =~ ' --ulo ' ]] && { shift 1; opt_ulo=1; }
	[[ " $* " =~ ' --all ' ]] && { shift 1; opt_all=1; }
	#(($# > 0)) && shift $(( $# - 1 ))
	local depl="${1:-$(rot.id.booted)}"
	[[ ! "${depl}" =~ ^[0-9]+$ ]] && { echo -e "Error: Deployment index must be a number" >&2; return 1; }
	local deployment_count=$(echo "$json_data" | jq '.deployments | length')
	[[ "${depl}" -ge "${deployment_count}" ]] && { echo -e "Error: Deployment index ${depl} out of range (total: ${deployment_count})" >&2; return 1; }
	local json_data_depl=$(echo "$json_data" | jq --raw-output --argjson idx "${depl}" '.deployments[$idx]')
	local pkg_full_list=""
	pkg_full_list+=$(echo "$json_data_depl" | jq --raw-output '.packages[]?');
	(( !opt_ulo || opt_all )) && { pkg_full_list+=$(echo "$json_data_depl" | jq --raw-output '.["base-commit-meta"].["ostree.container.image-config"] | fromjson | .config.Labels.["dev.hhd.rechunk.info"] | fromjson | .packages | keys[]'); }
	echo "${pkg_full_list}" | sort -u
}

rot.pl.diff() {
	local depl_old="${1:-1}"; [[ ! "${depl_old}" =~ ^[0-9]+$ ]] && { echo -e "Old Deployment index must be a number (got ${depl_old})"; return 1; }
	local depl_new="${2:-$(rot.id.booted)}"; [[ ! "${depl_new}" =~ ^[0-9]+$ ]] && { echo -e "New Deployment index must be a number (got ${depl_new})"; return 1; }
	diff -u <(rot.pl "${depl_old}") <(rot.pl "${depl_new}") | perl -ne 'print if /^[+-]/'
}

rot.pl.diff.add() {
	rot.pl.diff "${1}" | grep -E "^\+" | tail -n+2 | sed 's/^[+-]//g'
}

rot.pl.diff.rem() {
	rot.pl.diff "${1}" | grep -E "^\-" | tail -n+2 | sed 's/^[+-]//g'
}

#rot.copr.enable() {
#	[[ ((($# == 0))) || (" $* " =~ ' --help ') ]] && {
#		echo -e "Usage: ${FUNCNAME[0]} <copr_owner>/<copr_project>
#Add a COPR repo.
#	--help	Display this help."
#	}
#	local repo_path="${1:?"Repo path is required"}"
#	(($# != 1)) && { echo -e "Command requires 1 argument"; return 0; }
#	local owner="$(dirname "${1}")"
#	local project="$(basename "${1}")"
#	local fedora_version
#	fedora_version=$(rpm -E %fedora)
#	local repo_url="https://copr.fedorainfracloud.org/coprs/${owner}/${project}/repo/fedora-${fedora_version}/${owner}-${project}-fedora-${fedora_version}.repo"
#	echo "${repo_url}"
#	local repo_file="/etc/yum.repos.d/_copr:${owner}:${project}.repo"
#	echo "${repo_file}"
#	#sudo tee "$repo_file" > /dev/null <<EOF
##$(curl -fsSL "$repo_url")
##EOF
#	#sudo rpm-ostree refresh-md
#}

# Wrap in $(cmd) for a bash array / space separated list
# To reinstall missing:
#rot install --apply-live -y $(rot_pl_diff | grep -E -v "^\+" | tail -n+2 | sed 's/^[-]//g')
