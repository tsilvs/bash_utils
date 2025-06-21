#!/bin/bash

# groups.list() {
# 	getent group
# }

# group.create() {
# 	groupadd
# }

# group.user.add() {
# 	local groups
# 	local username
# 	usermod --append --groups "${groups}" "${username}"
# }

# group.user.rem() {
# 	local groups
# 	local username
# 	usermod --remove --groups "${groups}" "${username}"
# }

# group.user.list() {
# 	lid --group --onlynames "${groupname}"
# }

# New default groups
# adduser --conf --add_extra_groups
# /etc/adduser.conf
# EXTRA_GROUPS=
# /etc/default/useradd
# /etc/shadow-maint/useradd-pre.d/
# /etc/shadow-maint/useradd-post.d/

# vvv Not going to work vvv
# Suggested new default groups
# shared - for shared system files
# mkdir -p /var/local/bin
# sudo chown --recursive :shared /var/local/bin
# sudo semanage fcontext --add --type bin_t "/var/local/bin(/.*)?"
# sudo chmod --recursive g+rwxs /var/local/bin
# sudo restorecon -Rv /var/local/bin
# export PATH="/var/local/bin:$PATH"
# ^^^ Not going to work ^^^