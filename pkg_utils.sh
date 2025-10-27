#!/usr/bin/env bash

# List current existing packages

# set -euo pipefail # crashes the script for some reason

# Get the script's directory

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

source "$SCRIPT_DIR/lib/bashlib.sh"
source "$SCRIPT_DIR/rpm_ostree_utils.sh"

# have_cmd() { command -v "$1" &>/dev/null; }

# ---- Debian/Ubuntu (apt) ----------------------------------------------------
pkgls.deb() {
		# Prefer dpkg-query to avoid apt headers/noise; falls back to apt list
	if have_cmd dpkg-query; then
		dpkg-query -W -f='${binary:Package}\n' 2>/dev/null | sort -u
	else
		apt list --installed 2>/dev/null | awk -F/ 'NR>1{print $1}' | sort -u
	fi
}

# ---- Arch ----------------------------------------------------------
pkgls.pacman() {
	pacman -Qqe 2>/dev/null | sort -u
}

# ---- RPM ----------------------------------------
pkgls.rpm() {
	rpm -qa --qf '%{NAME}\n' 2>/dev/null | sort -u
}

pkgls.rpm-ostree() {
	rot.pl --ulo | sort -u
}

# ---- Gentoo (Portage) -------------------------------------------------------
pkgls.portage() {
	grep -v '^\s*$' /var/lib/portage/world
}

# ---- Flatpak ----------------------------------------------------------------
pkgls.flatpak.s() {
	flatpak list --system --app --columns=application 2>/dev/null | awk 'NF' | sort -u
}

pkgls.flatpak.u() {
	flatpak list --user --app --columns=application 2>/dev/null | awk 'NF' | sort -u
}

# ---- Homebrew (macOS/Linuxbrew) --------------------------------------------
pkgls.brew() {
	# brew bundle dump --file=- --force 2>/dev/null
	brew list -1 --installed-on-request
}

# ---- Node.js (npm) ----------------------------------------------------------
pkgls.npm() {
	npm ls --global --depth=0 --parseable 2>/dev/null | awk 'NR>1{print $0}' | awk -F/ '{print $NF}' | sort -u
}

# # ---- Node.js (pnpm) ---------------------------------------------------------
# pkgls.pnpm() {
# 	pnpm ls --global --depth=0 --parseable 2>/dev/null | awk 'NR>1{print $0}' | awk -F/ '{print $NF}' | sort -u
# }

# ---- pip -----------------------------------------------------------
pkgls.pip() {
	pip list --format=columns --not-required 2>/dev/null | awk 'NR>2 {print $1}'
}

# ---- pipx -------------------------------------------
pkgls.pipx.s() {
	pipx list --global --short 2>/dev/null | awk '{print $1}'
}

pkgls.pipx.u() {
	pipx list --short 2>/dev/null | awk '{print $1}'
}

# ---- Ruby (gem) -------------------------------------------------------------
pkgls.gem() {
	gem list --no-versions --local 2>/dev/null
}
# ---- GNOME Shell Extensions -------------------------------------------------
pkgls.gnome.s() {
	gnome-extensions list --system --enabled 2>/dev/null
}

pkgls.gnome.u() {
	gnome-extensions list --user --enabled 2>/dev/null
}

# ---- Containers ----------------------------------------------------
# ---- podman ----------------------------------------------------
pkgls.podman() {
	podman images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null
}

# ---- Visual Studio Code Extensions -----------------------------------------
pkgls.vscode() {
	code --list-extensions 2>/dev/null # TODO: Filter globally active
}

pkgls.code() {
	pkgls.vscode "$@"
	return $?
}

pkgls.all() {

	local exportDir # TODO: Set from params

	if have_cmd apt; then
		echo "# Packages for apt"
		pkgls.deb
	fi

	if have_cmd pacman; then
		echo "# Packages for pacman"
		pkgls.pacman
	fi

	if have_cmd rpm; then
		echo "# Packages for rpm"
		if have_cmd rpm-ostree; then
			pkgls.rpm-ostree
		else
			pkgls.rpm
		fi
	fi

	if have_cmd emerge && [ -r /var/lib/portage/world ]; then
		echo "# Packages for emerge"
		pkgls.portage
	fi

	if have_cmd flatpak; then
		echo "# Packages for flatpak"
		echo "## System"
		pkgls.flatpak.s
		echo "## User"
		pkgls.flatpak.u
	fi

	if have_cmd brew; then
		echo "# Packages for brew"
		pkgls.brew
	fi

	if have_cmd npm; then
		echo "# Packages for npm"
		pkgls.npm
	fi

	# if have_cmd pnpm; then
	# 	echo "# Packages for pnpm"
	# 	pkgls.pnpm
	# fi

	if have_cmd pipx; then
		echo "# Packages for pipx"
		echo "## System"
		pkgls.pipx.s
		echo "## User"
		pkgls.pipx.u
	fi

	if have_cmd gem; then
		echo "# Packages for gem"
		pkgls.gem
	fi

	if have_cmd gnome-extensions; then
		echo "# Packages for gnome"
		echo "## System"
		pkgls.gnome.s
		echo "## User"
		pkgls.gnome.u
	fi

	if have_cmd podman; then
		echo "# Packages for podman"
		pkgls.podman
	fi

	if have_cmd code; then
		echo "# Packages for code"
		pkgls.code
	fi
}


