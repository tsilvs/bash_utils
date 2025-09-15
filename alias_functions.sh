#!/usr/bin/env bash

neofetch.() {
	fastfetch "$@"
	return $?
}

fetch.() {
	fastfetch "$@"
	return $?
}

# ### Bookmarks
# #alias cdmyrepo="cd /mnt/data/myrepo/"

ls.() {
	ls --color --group-directories-first "$@"
	return $?
}

lsw() {
	local dir="${1:?"Directory is required."}"
	local name="${2:?"File name wildcard template is required."}"
	find -L "${dir}" -wholename "${name}" -ls
	return $?
}

catw() {
	local dir="${1:?"Directory is required."}"
	local name="${2:?"File name wildcard template is required."}"
	find -L "${dir}" -wholename "${name}" -exec cat {} \;
	return $?
}

lsd.() {
	lsd -1 -A -G -X --color always --group-dirs first -l -g "$@"
	return $?
}

eza.() {
	eza -1AlF --color=always --icons=always --group-directories-first --smart-group --git-repos "$@"
	return $?
}

md.() {
	mkdir "$@"
	return $?
}

rename.() {
	prename "$@"
	return $?
}

# mvall() {
# 	local match="${1}"
# 	local ext="${2}"
# 	for file in $match; do mv "$file" "${file%.}.${ext}"; done
# }

# pgrep.() {
# 	local pipe # TODO: Accept pipe stdin
# 	local file # TODO: Accept file path
# 	local regex="${1:?"Regex required."}"
# 	perl -ne "print if /${regex}/"
# 	return $?
# }

# #### For flatpaks

# # alias appfp='flatpak run tld.author.app'

af.flat.template() {
	local command="${1:?"Command is required."}"
	local package="${2:?"Package is required."}"
	echo -e "${command}(){\n\tflatpak run --command=\"${command}\" --file-forwarding ${package} \"\$@\"\n\treturn \$?\n}"
	return $?
}

keepassxc-cli() {
	flatpak run --command="keepassxc-cli" --file-forwarding org.keepassxc.KeePassXC "$@"
	return $?
}

codium() {
	flatpak run --command=com.vscodium.codium --file-forwarding com.vscodium.codium "$@"
	return $?
}

code() {
	codium "$@"
	return $?
}

npm() {
	pnpm "$@"
	return $?
}

chromium() {
	flatpak run --command=chromium --file-forwarding io.github.ungoogled_software.ungoogled_chromium "$@"
	return $?
}

# #### For distrobox apps

# ##### Arch

# alias gitbatch_db_a='distrobox enter arch -- gitbatch'
# alias pacmana='toolbox run --container arch pacman'
# alias microa='toolbox run --container arch micro'
# alias pandoca='toolbox run --container arch pandoc'

# ##### Fedora

# alias dnftb='toolbox run --container fedora sudo dnf'
# alias rpmtb='toolbox run --container fedora sudo rpm'
# alias yumtb='toolbox run --container fedora sudo yum'
# alias pandoc='toolbox run --container fedora pandoc'
# alias pandoctb='toolbox run --container fedora pandoc'
# alias libreofficetb='toolbox run --container fedora libreoffice'
# alias ffmpegtb='toolbox run --container fedora ffmpeg'
# alias lyxtb='toolbox run --container fedora lyx'
# alias abiwordtb='toolbox run --container fedora abiword'
# alias pdf2dsctb='toolbox run --container fedora pdf2dsc'
# alias pdfattachtb='toolbox run --container fedora pdfattach'
# alias pdffontstb='toolbox run --container fedora pdffonts'
# alias pdflatextb='toolbox run --container fedora pdflatex'
# alias pdfsigtb='toolbox run --container fedora pdfsig'
# alias pdftohtmltb='toolbox run --container fedora pdftohtml'
# alias pdftotexttb='toolbox run --container fedora pdftotext'
# alias pdf2pstb='toolbox run --container fedora pdf2ps'
# alias pdfdetachtb='toolbox run --container fedora pdfdetach'
# alias pdfimagestb='toolbox run --container fedora pdfimages'
# alias pdflatex-devtb='toolbox run --container fedora pdflatex-dev'
# alias pdftextb='toolbox run --container fedora pdftex'
# alias pdftoppmtb='toolbox run --container fedora pdftoppm'
# alias pdfunitetb='toolbox run --container fedora pdfunite'
# alias pdfatfitb='toolbox run --container fedora pdfatfi'
# alias pdfetextb='toolbox run --container fedora pdfetex'
# alias pdfinfotb='toolbox run --container fedora pdfinfo'
# alias pdfseparatetb='toolbox run --container fedora pdfseparate'
# alias pdftocairotb='toolbox run --container fedora pdftocairo'
# alias pdftopstb='toolbox run --container fedora pdftops'