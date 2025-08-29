#!/bin/bash

rot() { rpm-ostree "$@"; return $?; }
rot.install() { rot install --idempotent --apply-live --assumeyes "$@"; return $?; }
rot.i() { rot.install "$@"; return $?; }
rot.uninstall() { rot uninstall --idempotent --assumeyes "$@"; return $?; }
rot.u() { rot.uninstall "$@"; return $?; }
rot.search() { rot search "$@" | sort -u | perl -ne 'print if /^[^=]/'; return $?; }
rot.s() { rot.search "$@"; return $?; }

rot.booted() {
	[[ " $* " =~ ' --help ' ]] && {
		echo -e "Usage: ${FUNCNAME[0]} [OPTIONS] [properties]
Get information about the currently booted deployment.
	--index	print deployment index
"
		return 0
	}
	local json_data=$(rpm-ostree status --json) || { echo "Error: Failed to get rpm-ostree status" >&2; return 1; }
	local deployments=$(echo "$json_data" | jq '.deployments')
	[[ " $* " =~ ' --index ' ]] && {
		local booted_index=$(echo "$deployments" | jq 'to_entries[] | select(.value.booted) | .key') || { echo "Error: Failed to get booted index" >&2; return 1; }
		shift 1
		echo "$booted_index"
		return 0
	}
	local booted_deployment=$(echo "$deployments" | jq '.[] | select(.booted)') || { echo "Error: Failed to get booted deployment data" >&2; return 1; }
	local props=($@)
	[[ ${#props[@]} -eq 0 ]] && { echo "$booted_deployment"; return 0; }
	for prop in "${props[@]}"; do
		echo -e "$prop:\t$(echo "$booted_deployment" | jq --raw-output ".${prop}")"
	done
}

# rot.booted.dir() {
# 	local depl_booted_serial="$(rpm-ostree status --json | jq --raw-output '.deployments[] | select(.booted) | .serial')"
# 	local depl_booted_checksum="$(rpm-ostree status --json | jq --raw-output '.deployments[] | select(.booted) | .checksum')"
# 	local depl_booted_osname="$(rpm-ostree status --json | jq --raw-output '.deployments[] | select(.booted) | .osname')"
# 	local depl_booted_root_dir_path="/ostree/deploy/${depl_booted_osname}/deploy/${depl_booted_checksum}.${depl_booted_serial}"
# }

rot.repos.list() {
	[[ " $* " =~ ' --help ' ]] && {
		echo -e "Usage: ${FUNCNAME[0]} [OPTIONS] [DEPLOYMENT_INDEX]
List repos in a deployment (default index: 0).
	--help	Show this help
"
		return 0
	}
	local json_data=$(rpm-ostree status --json) || { echo -e "Error: Failed to get rpm-ostree status" >&2; return 1; }
	local depl="${1:-$(rot.booted --index)}"
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
	local depl="${1:-$(rot.booted --index)}"
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
	local depl_new="${2:-$(rot.booted --index)}"; [[ ! "${depl_new}" =~ ^[0-9]+$ ]] && { echo -e "New Deployment index must be a number (got ${depl_new})"; return 1; }
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


#   121  rot install --apply-live -y jami
#   195  rot install --apply-live -y humanode-launcher
#   209  rot install --apply-live -y humanode-launcher
#   252  rot install --apply-live -y yq
#   255  rot install --apply-live -y yq
#   257  rot install --apply-live -y yq
#   391  rot install --apply-live -y Downloads/gb-studio-linux-redhat.rpm
#   413  rot install --apply-live -y codium{,-marketplace}
#   416  rot install --apply-live -y codium
#   544  rot install --apply-live -y openproject
#   833  rot install --apply-live -y pgcli pgadmin4 postgresql{,-{server,docs,test,pltcl}}
#   834  rot install --apply-live -y pgcli postgresql{,-{server,docs,test,pltcl}}
#  1029  rot install --apply-live -y squashfs-tools
#  1049  rot install --apply-live -y edk2-ovmf
#  1306  rot install --apply-live -y gnome-shell-extension-gsconnect webextension-gsconnect nautilus-gsconnect
#  1307  rot install --apply-live -y webextension-gsconnect nautilus-gsconnect
#  1308  rot install --apply-live -y webextension-gsconnect
#  1529  rot install --apply-live -y yq
#  1533  rot install --apply-live -y yq
#  1835  rot install --apply-live -y perl-Image-ExifTool
#  2205  rot install --apply-live -y yq TightVNC gh glab
#  2206  rot install --apply-live -y TightVNC gh glab
#  2207  rot install --help | grep -i current
#  2208  rot install --help | grep -i booted
#  2209  rot install --apply-live -y gh glab tightvnc{,-server}
#  2210  rot install --apply-live -y glab tightvnc{,-server}
#  2211  rot install --apply-live -y tightvnc{,-server}
#  2884  rot_id_booted
#  2915  rot install --apply-live -y $(rot_pl_diff 2 | grep -E -v "^\+" | tail -n+2 | sed 's/^[-]//g')
#  2918  rot install --apply-live -y webextension-gsconnect gnome-shell-extension-argos
#  2983  rot install python-git-batch
#  2989  rot install --apply-live -y alien
#  2996  rot install --apply-live -y handbrake
#  3435  rot install --apply-live -y handbrake
#  3438  rot.id.booted
#  3440  rot.id.booted
#  3450  rot.id.booted
#  3452  rot.id.booted
#  3460  rot.id.booted
#  3462  rot.id.booted
#  3463  rot.id.booted --version
#  3476  rot.id.booted --version
#  3477  rot.id.booted
#  3479  rot.id.booted
#  3488  rot.id.booted
#  3489  rot.id.booted --version
#  3490  rot.id.booted --version-only
#  3541  rot install --apply-live -y ollama
#  3549  rot install --apply-live -y nerdfontssymbolsonly-nerd-fonts
#  3654  rot.id.booted
#  3674  rot_i gnome-tweaks
#  3783  rot_i strace
#  3825  rot_i radeontop
#  3988  rot_i zig
#  3989  rot_i golang
#  4045  rot_i wine{,-{desktop,dxvk,opencl,systemd},tricks}
#  4046  rot_i wine{,-{desktop,systemd},tricks}
#  4047  rot_i wine-core
#  4053  rot_i skopeo
#  4250  rot_i rocm-hip rocm-opencl rocm-runtime rocminfo
#  4251  rot_i rocm-opencl rocm-runtime rocminfo
#  4252  rot_i rocm-runtime rocminfo
#  4253  rot_i rocminfo
#  4363  rot_i ~/Downloads/dive_0.13.1_linux_arm64.rpm
#  4365  rot_i ~/Downloads/dive_0.13.1_linux_amd64.rpm
#  4884  rot_i chezmoi
#  4885  rot_i --help
#  4886  rot_i --uninstall=toolbox
#  4887  which rot_i
#  4889  which rot_i
#  4891  diff -u <(rot install --help) <(rot uninstall --help)
#  4914  rot_i chezmoi
#  5145  rot.id.booted
#  5333  rot_i crudini
#  5334  history | grep rot.install
#  5335  history | grep rot_i
#  5467  rot.id.booted
#  5468  rot.id.booted --version
#  5610  rot.install cargo
#  5611  rot_i cargo
#  5621  rot.install cargo
#  5622  rot_i cargo
#  5936  rot.install clang
#  5937  rot_i clang
#  6060  rot_i converseen
#  6554  rot_i pavucontrol
#  6665  rot_i update
#  6821  rot.i shfmt
#  6864  rot.i ripgrep
#  6871  HISTTIMEFORMAT="" history | grep -E "rot.i"
#  6872  HISTTIMEFORMAT="" history | grep -E "rot.i" >> ~/Desktop/rot.debug.installs.hist
#   381  rot upgrade
#  1174  rot upgrade
#  1261  rot upgrade
#  1265  rot upgrade
#  1267  rot upgrade
#  1275  rot upgrade
#  1278  rot upgrade
#  1289  rot uninstall copy-jdk-configs grub-customizer plantuml-javadoc
#  1290  rot uninstall elfutils qemu-common qemu-system-riscv rocm-smi qemu-img qemu-system-aarch64 qemu-system-x86 boost-iostreams bison rpmdevtools rpm-build qemu-system-arm chkconfig sunshine
#  1296  rot upgrade
#  1297  rot uninstall gnome-shell-extension-argos jami jami-daemon webextension-gsconnect gnome-shell-extension-gsconnect
#  1298  rot uninstall gnome-shell-extension-argos jami webextension-gsconnect gnome-shell-extension-gsconnect
#  1299  rot uninstall gnome-shell-extension-argos jami webextension-gsconnect
#  1300  rot upgrade
#  2978  rot usroverlay --help
#  4891  diff -u <(rot install --help) <(rot uninstall --help)
#  6666  rot update
#  6866  rot.u R cabal alien
#  6867  rot.u R
#  6868  rot.u cabal
#  6869  rot.u alien
#  6873  HISTTIMEFORMAT="" history | grep -E "rot.u"
#  6874  HISTTIMEFORMAT="" history | grep -E "rot.u" >> ~/Desktop/rot.debug.uninstalls.hist
