#!/bin/bash

# Ostree Utils

# Requires ostree~='2025.2'

ostree.depls() {
	ostree admin status "$@"
	return $?
}

ostree.depl.booted() {
	ostree.depls "$@" | perl -ne 'print if /^[*]/' | awk --field-separator " " '{ print $3 }'
	return $?
}

ostree.depl.booted.commithash() {
	ostree.depl.booted "$@" | awk --field-separator "." '{ print $1 }'
	return $?
}

ostree.depl.booted.i() {
	# ostree.depls "$@" | perl -ne 'print if !/^[ ]{4}/' | grep --fixed-strings --line-number "$(ostree.depl.booted)" | cut -f1 -d:
	ostree.depls "$@" | perl -ne 'print if !/^[ ]{4}/' | awk "/$(ostree.depl.booted)/ {print FNR-1}"
	return $?
}

ostree.depl.booted.checkout() {
	ostree checkout "$(ostree.depl.booted.commithash)" "$@"
	return $?
}

# Terminology

# Deployment - a commit that's marked as a bootable version of the OS. Can be referred to by a numerical index (0++).
# Origin - repository available by an URL, description stored in an origin file
# Sysroot - "System Root", a physical location storing repo and deployments
# bootc - ?

# /ostree/deploy/<os-name>
# Here we can have deployments of different OSes stored in parallel

# Typical file locations
# `/sysroot` - system root
# tree -L 4 /sysroot
# ├── boot
# ├── dev
# ├── home
# ├── ostree
# │   ├── boot.1 -> boot.1.1
# │   ├── boot.1.1
# │   │   └── default
# │   │       ├── 170de07ff6d625f54e4ad0e3958136b1cfa481093de0dbd27a6ab142ddd772d5
# │   │       └── 83b7b1437007bbebfb9fbdfd35bb3e0b90bb13bcfa7065a69afe441c676b44d7
# │   ├── deploy
# │   │   └── default
# │   │       ├── backing
# │   │       ├── deploy
# │   │       └── var
# │   └── repo
# │       ├── extensions
# │       │   └── rpmostree
# │       ├── objects
# │       │   ├── 00
# │       │   ├── ...
# │       │   └── ff
# │       ├── refs
# │       │   ├── heads
# │       │   ├── mirrors
# │       │   └── remotes
# │       ├── state
# │       ├── tmp
# │       │   └── cache
# │       └── config
# ├── proc
# ├── root
# ├── run
# ├── sys
# ├── tmp
# └── var

# ostree
# ostree --help
# ostree admin
# ostree admin --help
# ostree admin commit --help
# ostree admin deploy --help
# # ostree admin pin 0
# # ostree admin pin 2 --unpin
# ostree admin set-origin --help
# ostree admin status
# ostree admin status --help
# ostree admin status --is-default
# ostree admin status | yq
# ostree admin status | yq --input-format
# ostree admin status | yq --raw-input
# ostree admin undeploy --help
# # ostree admin undeploy 2
# # ostree admin unlock
# # ostree admin unpin 2
# ostree init --help
# ostree rebase --help
# ostree refs
# ostree refs --help
# ostree refs --list
# ostree refs --list ostree
# ostree refs --list ostree/1
# ostree refs --list rpmostree
# ostree refs --list rpmostree/base
# ostree remote show-url
# ostree remote show-url fedora
# ostree remote show-url origin
# ostree show ostree/1/1/0

# for ref in $(ostree refs); do
# 	echo "Ref: $ref";
# 	ostree show "$ref" 2>/dev/null | perl -ne 'print if /^(commit|Version|osname|ID|Summary|origin|parent|Timestamp|Subject|tree:)/';
# 	echo;
# done
# for ref in $(ostree refs); do
# 	echo "Ref: $ref";
# 	ostree show "$ref" 2>/dev/null | perl -ne 'print if /^(Version|osname|ID|Summary|origin|parent|Timestamp|Subject)/';
# 	echo;
# done
# for ref in $(ostree refs); do
# 	ostree show "$ref" 2>/dev/null | perl -ne 'print if /^(Version|osname|ID|Summary|origin|parent|Timestamp|Subject)/';
# 	echo;
# done

# https://man.archlinux.org/man/ostree.1.en#NAME
# https://man.archlinux.org/man/ostree.1.en#SYNOPSIS
# https://man.archlinux.org/man/ostree.1.en#DESCRIPTION
# https://man.archlinux.org/man/ostree.1.en#OPTIONS
# https://man.archlinux.org/man/ostree.1.en#COMMANDS
# https://man.archlinux.org/man/ostree-admin-cleanup.1.en
# https://man.archlinux.org/man/ostree-admin-config-diff.1.en
# https://man.archlinux.org/man/ostree-admin-deploy.1.en
# https://man.archlinux.org/man/ostree-admin-init-fs.1.en
# https://man.archlinux.org/man/ostree-admin-instutil.1.en
# https://man.archlinux.org/man/ostree-admin-os-init.1.en
# https://man.archlinux.org/man/ostree-admin-status.1.en
# https://man.archlinux.org/man/ostree-admin-switch.1.en
# https://man.archlinux.org/man/ostree-admin-undeploy.1.en
# https://man.archlinux.org/man/ostree-admin-upgrade.1.en
# https://man.archlinux.org/man/ostree-cat.1.en
# https://man.archlinux.org/man/ostree-checkout.1.en
# https://man.archlinux.org/man/ostree-checksum.1.en
# https://man.archlinux.org/man/ostree-commit.1.en
# https://man.archlinux.org/man/ostree-config.1.en
# https://man.archlinux.org/man/ostree-create-usb.1.en
# https://man.archlinux.org/man/ostree-diff.1.en
# https://man.archlinux.org/man/ostree-find-remotes.1.en
# https://man.archlinux.org/man/ostree-fsck.1.en
# https://man.archlinux.org/man/ostree-init.1.en
# https://man.archlinux.org/man/ostree-log.1.en
# https://man.archlinux.org/man/ostree-ls.1.en
# https://man.archlinux.org/man/ostree-prune.1.en
# https://man.archlinux.org/man/ostree-pull-local.1.en
# https://man.archlinux.org/man/ostree-pull.1.en
# https://man.archlinux.org/man/ostree-refs.1.en
# https://man.archlinux.org/man/ostree-remote.1.en
# https://man.archlinux.org/man/ostree-reset.1.en
# https://man.archlinux.org/man/ostree-rev-parse.1.en
# https://man.archlinux.org/man/ostree-show.1.en
# https://man.archlinux.org/man/ostree-static-delta.1.en
# https://man.archlinux.org/man/ostree-summary.1.en
# https://man.archlinux.org/man/ostree.1.en#EXAMPLES
# https://man.archlinux.org/man/ostree.1.en#GPG_VERIFICATION
# https://man.archlinux.org/man/ostree.1.en#TERMINOLOGY
# https://man.archlinux.org/man/ostree.1.en#SEE_ALSO
# https://man.archlinux.org/man/ostree.repo.5.en
# https://man.archlinux.org/man/ostree.1.en.txt
# https://man.archlinux.org/man/ostree.1.en.raw