#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

source "${SCRIPT_DIR}/aliases.flatpak.sh"

neofetch.() {
	/usr/bin/fastfetch "$@"
	return $?
}

fetch.() {
	/usr/bin/fastfetch "$@"
	return $?
}

fetch.ls() {
	fetch. \
		--key-type string \
		--logo none\
		--structure os:host:kernel:de:wm:terminal:cpu:gpu:gpu2:memory:swap:disk:localip:locale
}

sysinfo.fetch() {
	fetch.ls "$@"
	return $?
}

# ### Bookmarks
# #alias cdmyrepo="cd /mnt/data/myrepo/"

ls.() {
	ls --color --group-directories-first "$@"
	return $?
}

ls.join() {
	local path_A path_B full_path=false join_type=""
	local display_A display_B
	
	while [[ $# -gt 0 ]]; do
		case $1 in
			-i|--inner) join_type="inner"; shift ;;
			-o|--outer) join_type="outer"; shift ;;
			-f|--full-path) full_path=true; shift ;;
			-*) echo "Unknown option: $1" >&2; return 1 ;;
			*)
				if [[ -z "$path_A" ]]; then
					path_A="$1"
					display_A="${1/#$HOME/\~}"
				elif [[ -z "$path_B" ]]; then
					path_B="$1"
					display_B="${1/#$HOME/\~}"
				else
					echo "Too many arguments" >&2; return 1
				fi
				shift ;;
		esac
	done
	
	[[ -z "$join_type" ]] && { echo "Usage: ls.join [--inner|--outer] [-f|--full-path] path_A path_B" >&2; return 1; }
	[[ -z "$path_A" || -z "$path_B" ]] && { echo "Usage: ls.join [--inner|--outer] [-f|--full-path] path_A path_B" >&2; return 1; }
	[[ -d "$path_A" ]] || { echo "Error: $path_A not a directory" >&2; return 1; }
	[[ -d "$path_B" ]] || { echo "Error: $path_B not a directory" >&2; return 1; }
	
	path_A="${path_A%/}"
	path_B="${path_B%/}"
	display_A="${display_A%/}"
	display_B="${display_B%/}"
	
	echo "| Path A | Path B |"
	echo "|--------|--------|"
	
	if [[ "$join_type" == "inner" ]]; then
		comm -12 <(ls -1 "$path_A" | sort) <(ls -1 "$path_B" | sort) |
			if [[ "$full_path" == true ]]; then
				awk -v a="$display_A" -v b="$display_B" '{ print "| `" a "/" $0 "` | `" b "/" $0 "` |" }'
			else
				awk '{ print "| `" $0 "` | `" $0 "` |" }'
			fi
	else
		if [[ "$full_path" == true ]]; then
			comm -3 <(ls -1 "$path_A" | sort) <(ls -1 "$path_B" | sort) |
				awk -v a="$display_A" -v b="$display_B" '
					/^\t/ { sub(/^\t/, ""); print "| | `" b "/" $0 "` |"; next }
					{ print "| `" a "/" $0 "` | |" }
				'
			
			comm -12 <(ls -1 "$path_A" | sort) <(ls -1 "$path_B" | sort) |
				awk -v a="$display_A" -v b="$display_B" '{ print "| `" a "/" $0 "` | `" b "/" $0 "` |" }'
		else
			comm -3 <(ls -1 "$path_A" | sort) <(ls -1 "$path_B" | sort) |
				awk '
					/^\t/ { sub(/^\t/, ""); print "| | `" $0 "` |"; next }
					{ print "| `" $0 "` | |" }
				'
			
			comm -12 <(ls -1 "$path_A" | sort) <(ls -1 "$path_B" | sort) |
				awk '{ print "| `" $0 "` | `" $0 "` |" }'
		fi
	fi
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

catp() {
	# Example: catp '[\d]+.*[.]md'
	local pattern="${1:?"Pattern is required."}"
	cat $(ls -1 | grep -P "${pattern}")
	# If `grep`` is without PCRE (`perl`) support: use `ls -1 | perl -ne "print if /${pattern}/"`
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

mktouch() {
	if [ $# -eq 0 ]; then
		echo "No file paths supplied."
		return 1
	fi
	for filepath in "$@"; do
		mkdir -p "$(dirname "$filepath")" && touch "$filepath"
	done
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

# npm() {
# 	pnpm "$@"
# 	return $?
# }




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

# ###### pdf tools
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
# alias pdftopstb='toolbox run --container fedora pdftops


