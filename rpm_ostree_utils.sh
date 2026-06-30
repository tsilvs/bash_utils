#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bashlib.sh"
source "${SCRIPT_DIR}/lib/cli.sh"

rot() {
	rpm-ostree "$@"
	return $?
}
rot.install() {
	rot install --idempotent --apply-live --assumeyes "$@"
	return $?
}
rot.i() {
	rot.install "$@"
	return $?
}
rot.uninstall() {
	rot uninstall --idempotent --assumeyes "$@"
	return $?
}
rot.u() {
	rot.uninstall "$@"
	return $?
}
rot.search() {
	rot search "$@" | sort -u | perl -ne 'print if /^[^=]/'
	return $?
}
rot.s() {
	rot.search "$@"
	return $?
}

rot.booted() {
	local showhelp=0 show_index=0 props=()
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			;;
		--index)
			show_index=1
			;;
		--)
			shift
			break
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*)
			props+=("$1")
			;;
		esac
		shift
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [OPTIONS] [properties...]
			Get information about the currently booted deployment.
			  --index  print deployment index
			  --help   Show this help
		EOF
		return 0
	}
	local json_data
	json_data=$(rpm-ostree status --json) || {
		echo "Error: Failed to get rpm-ostree status" >&2
		return 1
	}
	local deployments
	deployments=$(echo "$json_data" | jq '.deployments')
	if ((show_index)); then
		local booted_index
		booted_index=$(echo "$deployments" | jq 'to_entries[] | select(.value.booted) | .key') || {
			echo "Error: Failed to get booted index" >&2
			return 1
		}
		echo "$booted_index"
		return 0
	fi
	local booted_deployment
	booted_deployment=$(echo "$deployments" | jq '.[] | select(.booted)') || {
		echo "Error: Failed to get booted deployment data" >&2
		return 1
	}
	[[ ${#props[@]} -eq 0 ]] && {
		echo "$booted_deployment"
		return 0
	}
	for prop in "${props[@]}"; do
		echo -e "$prop:\t$(echo "$booted_deployment" | jq --raw-output ".${prop}")"
	done
}

rot.booted.version() {
	rot.booted "$@" | jq -r '.version'
	return $?
}

# rot.booted.dir() {
# 	local depl_booted_serial="$(rpm-ostree status --json | jq --raw-output '.deployments[] | select(.booted) | .serial')"
# 	local depl_booted_checksum="$(rpm-ostree status --json | jq --raw-output '.deployments[] | select(.booted) | .checksum')"
# 	local depl_booted_osname="$(rpm-ostree status --json | jq --raw-output '.deployments[] | select(.booted) | .osname')"
# 	local depl_booted_root_dir_path="/ostree/deploy/${depl_booted_osname}/deploy/${depl_booted_checksum}.${depl_booted_serial}"
# }

rot.repos.list() {
	local showhelp=0
	while (($#)) && [[ "$1" == -* ]]; do
		case "$1" in
		--help | -h)
			showhelp=1
			shift
			;;
		*) break ;;
		esac
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [OPTIONS] [DEPLOYMENT_INDEX]
			List repos in a deployment (default index: 0).
			  --help  Show this help
		EOF
		return 0
	}
	local json_data=$(rpm-ostree status --json) || {
		echo -e "Error: Failed to get rpm-ostree status" >&2
		return 1
	}
	local depl="${1:-$(rot.booted --index)}"
	[[ ! "${depl}" =~ ^[0-9]+$ ]] && {
		echo -e "Error: Deployment index must be a number" >&2
		return 1
	}
	local deployment_count=$(echo "$json_data" | jq '.deployments | length')
	[[ "${depl}" -ge "${deployment_count}" ]] && {
		echo -e "Error: Deployment index ${depl} out of range (total: ${deployment_count})" >&2
		return 1
	}
	local json_data_depl=$(echo "$json_data" | jq --argjson idx "${depl}" '.deployments[$idx]')
	local repos=$(echo "${json_data_depl}" | jq --raw-output '.["layered-commit-meta"].["rpmostree.rpmmd-repos"][].["id"]' | sort -u)
	echo "${repos}"
}

#rot.repo.url() {
#
#}

rot.pl() {
	local showhelp=0 show_lskeys=0 show_lsdeps=0 show_lsdepsver=0 opt_ulo=0 opt_all=0 depl=""
	while (($#)); do
		case "$1" in
		--help | -h)
			showhelp=1
			;;
		--lskeys)
			show_lskeys=1
			;;
		--lsdeps)
			show_lsdeps=1
			;;
		--lsdepsver)
			show_lsdepsver=1
			;;
		--ulo)
			opt_ulo=1
			;;
		--all)
			opt_all=1
			;;
		--)
			shift
			break
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 1
			;;
		*)
			[[ -z "$depl" ]] && depl="$1" || {
				echo "Error: unexpected argument: $1" >&2
				return 1
			}
			;;
		esac
		shift
	done
	((showhelp)) && {
		cat <<-EOF
			Usage: ${FUNCNAME[0]} [OPTIONS] [DEPLOYMENT_INDEX]
			List packages from a specific deployment in rpm-ostree (default: index 0).
			  --lskeys      List top level keys
			  --lsdeps      List deployment indexes
			  --lsdepsver   List deployment indexes with versions
			  --ulo         User layered only
			  --all         All packages
			  --help        Show this help
		EOF
		return 0
	}
	local json_data
	json_data=$(rpm-ostree status --json) || {
		echo -e "Error: Failed to get rpm-ostree status" >&2
		return 1
	}
	((show_lskeys)) && {
		echo "${json_data}" | jq --raw-output 'keys[]'
		return 0
	}
	((show_lsdeps)) && {
		echo "${json_data}" | jq --raw-output '.deployments | keys[]'
		return 0
	}
	((show_lsdepsver)) && {
		echo "${json_data}" | jq --raw-output '.deployments | to_entries[] | "\(.key)\t\(.value.version)"'
		return 0
	}
	depl="${depl:-$(rot.booted --index)}"
	[[ ! "${depl}" =~ ^[0-9]+$ ]] && {
		echo -e "Error: Deployment index must be a number" >&2
		return 1
	}
	local deployment_count
	deployment_count=$(echo "$json_data" | jq '.deployments | length')
	[[ "${depl}" -ge "${deployment_count}" ]] && {
		echo -e "Error: Deployment index ${depl} out of range (total: ${deployment_count})" >&2
		return 1
	}
	local json_data_depl
	json_data_depl=$(echo "$json_data" | jq --raw-output --argjson idx "${depl}" '.deployments[$idx]')
	local pkg_full_list=""
	pkg_full_list+=$(echo "$json_data_depl" | jq --raw-output '.packages[]?')
	((!opt_ulo || opt_all)) && { pkg_full_list+=$(echo "$json_data_depl" | jq --raw-output '.["base-commit-meta"].["ostree.container.image-config"] | fromjson | .config.Labels.["dev.hhd.rechunk.info"] | fromjson | .packages | keys[]'); }
	echo "${pkg_full_list}" | sort -u
}

rot.pl.diff() {
	local depl_old="${1:-1}"
	[[ ! "${depl_old}" =~ ^[0-9]+$ ]] && {
		echo -e "Old Deployment index must be a number (got ${depl_old})"
		return 1
	}
	local depl_new="${2:-$(rot.booted --index)}"
	[[ ! "${depl_new}" =~ ^[0-9]+$ ]] && {
		echo -e "New Deployment index must be a number (got ${depl_new})"
		return 1
	}
	diff -u <(rot.pl "${depl_old}") <(rot.pl "${depl_new}") | perl -ne 'print if /^[+-]/'
}

rot.pl.diff.add() {
	rot.pl.diff "${1}" | grep -E "^\+" | tail -n+2 | sed 's/^[+-]//g'
}

rot.pl.diff.rem() {
	rot.pl.diff "${1}" | grep -E "^\-" | tail -n+2 | sed 's/^[+-]//g'
}

# rot.s.inst() {
# 	# TODO: param --description to include a description.
# 	local prefix="${1:?"Search prefix required"}"
# 	grep -f <(rot.pl --all | grep "${prefix}") <(rot.s "${prefix}") | awk --field-separator " : " '{ print $1 }'
# 	return $?
# }

# rot.s.ninst() {
# 	# TODO: param --description to include a description.
# 	local prefix="${1:?"Search prefix required"}"
# 	grep -v -f <(rot.pl --all | grep "${prefix}") <(rot.s "${prefix}") | awk --field-separator " : " '{ print $1 }'
# 	return $?
# }

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

# rot.swap.rm.by.uuid() {
# 	set -o errexit
# 	set -o pipefail
# 	set -o nounset

# 	local usage="NOT READY YET, DOES NOTHING
# Usage: ${FUNCNAME[0]} [OPTIONS] UUID
# Remove swap safely by UUID.
# 	-v, --verbose  Verbose messages
# 	-h, --help     Show this help
# "
# 	# -d, --dry-run  Show planned actions without changes to the system
# 	local verbose=0
# 	local showhelp=0
# 	# local dryrun=0
# 	local uuid=""

# 	# Parse options
# 	while (( "$#" )); do
# 		case "$1" in
# 			--verbose|-V) verbose=1; shift 1 ;;
# 			--help|-h) showhelp=1; shift 1 ;;
# 			# --dry-run|-d) dryrun=1; shift 1 ;;
# 			*) if [[ -z "$uuid" ]]; then uuid="${1}"; shift 1; else echo "Error: Unexpected argument ${1}"; showhelp=1; fi ;;
# 		esac
# 	done

# 	[[ -z "$uuid" ]] && { echo "Error: UUID is required"; showhelp=1; return 1; }

# 	(( showhelp )) && { echo -e "${usage}"; return 0; }

# 	# (( verbose )) && echo "Looking up swap device for UUID: $uuid"

# 	# # Resolve swap device path by UUID
# 	# local devpath="/dev/disk/by-uuid/$uuid"
# 	# [[ ! -e $devpath ]] && { echo "Error: No device found with UUID $uuid"; return 1; }

# 	# local swapdev
# 	# swapdev=$(readlink -f "$devpath")

# 	# (( verbose )) && echo "Swap device resolved to: $swapdev"

# 	# # Disable swap
# 	# (( verbose )) && echo "Turning off swap on $swapdev"
# 	# sudo swapoff "$swapdev"

# 	# # Comment out swap in /etc/fstab
# 	# if grep -q "UUID=$uuid" /etc/fstab; then
# 	# 	(( verbose )) && echo "Commenting out swap entry in /etc/fstab"
# 	# 	sudo sed -i.bak "/UUID=$uuid/ s/^/#/" /etc/fstab
# 	# else
# 	# 	(( verbose )) && echo "No matching swap entry in /etc/fstab to comment"
# 	# fi

# 	# # Remove resume=UUID= from kernel args using rpm-ostree if exists
# 	# if command -v rpm-ostree >/dev/null 2>&1; then
# 	# 	if rpm-ostree status | grep -q "kernel-args"; then
# 	# 		(( verbose )) && echo "Removing resume=UUID=$uuid from kernel arguments"
# 	# 		sudo rpm-ostree kargs --delete "resume=UUID=$uuid"
# 	# 		(( verbose )) && echo "Reboot required to apply kernel argument changes"
# 	# 	fi
# 	# else
# 	# 	(( verbose )) && echo "rpm-ostree not found, skipping kernel args clean up"
# 	# fi

# 	# (( verbose )) && echo "Swap removal by UUID $uuid completed"

# 	return 0
# }

export -f rot
export -f rot.install
export -f rot.i
export -f rot.uninstall
export -f rot.u
export -f rot.search
export -f rot.s
export -f rot.booted
export -f rot.booted.version
export -f rot.pl
export -f rot.pl.diff
export -f rot.pl.diff.add
export -f rot.pl.diff.rem
export -f rot.repos.list
# export -f rot.booted.dir
# export -f rot.copr.enable
# export -f rot.repo.url
# export -f rot.s.inst
# export -f rot.s.ninst
# export -f rot.swap.rm.by.uuid
register_simple_completion "rot"
register_simple_completion "rot.install"
register_simple_completion "rot.i"
register_simple_completion "rot.uninstall"
register_simple_completion "rot.u"
register_simple_completion "rot.search"
register_simple_completion "rot.s"
register_simple_completion "rot.booted" "--index"
register_simple_completion "rot.booted.version"
register_simple_completion "rot.repos.list"
register_simple_completion "rot.pl" "--lskeys" "--lsdeps" "--lsdepsver" "--ulo" "--all"
register_simple_completion "rot.pl.diff"
register_simple_completion "rot.pl.diff.add"
register_simple_completion "rot.pl.diff.rem"
