#!/usr/bin/env bash

# What finally worked:
# sudo grub2-editenv - unset menu_auto_hide

# === === Some history === ===
# grub2-mkconfig | sudo tee /boot/grub2/grub.cfg
# sudo cat /boot/grub2/grub.cfg
# sudo cat /boot/grub2/grubenv
# sudo cat /etc/default/grub
# sudo cat /boot/grub2/grub.cfg
# sudo cat /boot/grub2/user.cfg
# sudo cat /etc/grub2.cfg
# sudo cat /etc/grub.d/00_header
# sudo grub2-editenv - unset menu_auto_hide
# sudo grub2-mkconfig
# sudo grub2-mkconfig > grub_debug.cfg
# sudo nano /boot/grub2/grub.cfg
# sudo nano /boot/grub2/user.cfg
# sudo nano /etc/default/grub

# === === In `/etc/default/grub` === ===
# GRUB_TIMEOUT="35"
# GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
# GRUB_DEFAULT="saved"
# GRUB_DISABLE_SUBMENU="true"
# #GRUB_CMDLINE_LINUX="rd.luks.uuid=luks-225929e5-c017-48e9-b23b-0d657e59573a rhgb quiet"
# #GRUB_DISABLE_RECOVERY="false"
# GRUB_ENABLE_BLSCFG="true"
# #export GRUB_COLOR_NORMAL="light-gray/black"
# #export GRUB_COLOR_HIGHLIGHT="magenta/black"
# GRUB_THEME="/boot/grub2/themes/fedora/theme.txt"
# GRUB_GFXMODE="1920x1080"
# #GRUB_DISABLE_LINUX_RECOVERY="true"
# GRUB_TIMEOUT_STYLE=menu
# GRUB_FORCE_DISPLAY=true
# #GRUB_HIDDEN_TIMEOUT_QUIET="false"
# GRUB_TERMINAL="gfxterm"
# GRUB_TERMINAL_OUTPUT="gfxterm"

# === === In `/boot/grub2/user.cfg` === ===
# set timeout=30
# set timeout_style=menu
# #set menu_auto_hide=0
