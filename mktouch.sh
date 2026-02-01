#!/usr/bin/env bash

mktouch() {
	local paths=() show_tree=false dry_run=false
	
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help) cat <<-EOF
				Usage: ${FUNCNAME[0]} [OPTIONS] [--path|-p] <path> [<path> ...]
				Creates directories and files for given paths.
				
				Options:
				  -p, --path <path>   Specify path(s) to create
				  -t, --tree          Show tree of created structure
				  -n, --dryrun        Preview structure without creating
				  -h, --help          Display this help message
				
				Examples:
				  mktouch dir/file.txt
				  mktouch dir/         # Creates only directory
				  mktouch -t -p dir1/file1.txt dir2/file2.txt
				  mktouch -n path/{a,b,c}.txt
				EOF
				return 0 ;;
			-t|--tree) show_tree=true; shift ;;
			-n|--dryrun) dry_run=true; show_tree=true; shift ;;
			-p|--path) shift; [[ $# -eq 0 ]] && echo "Error: --path requires argument" && return 1
				paths+=("$1"); shift ;;
			-*) echo "Error: Unknown option $1" && return 1 ;;
			*) paths+=("$1"); shift ;;
		esac
	done
	
	[[ ${#paths[@]} -eq 0 ]] && echo "Error: No paths specified" && return 1
	
	if $dry_run; then
		printf '%s\n' "${paths[@]}" | tree --fromfile -F --noreport --dirsfirst
		return 0
	fi
	
	for path in "${paths[@]}"; do
		[[ "$path" == */ ]] && mkdir -p "$path" || { mkdir -p "$(dirname "$path")"; touch "$path"; }
	done
	
	$show_tree && tree -F --noreport --dirsfirst
}

# Git repo basics
mktouch.git() { mktouch "$@" .gitignore .github/FUNDING.yml README.md CODE_OF_CONDUCT.md CONTRIBUTING.md PUBLISH.md TESTS.md LICENSE; }

# VSCode configs
mktouch.vscode() { mktouch "$@" .vscode/{extensions.json,json.code-snippets,markdown.code-snippets,settings.json}; }

# Docs structure
mktouch.docs() { mktouch "$@" doc/dev/{0.std/{,core/,front/{,html/,pug/,css/,ts/,js/},back/,data/,infra/}README.md,1.req/{,1.US/,2.UC/,3.BRD/,4.SDD/}README.md,2.plan/README.md}; }

# Front dist/src (full)
mktouch.front_full() { mktouch "$@" dist/{html/pages/,css/{0.util/,1.cmp/{_1.icon,_2.btn,_3.card,_4.list,_5.form}.css,2.layout/_0.tab.css,3.page/{_1.landscape,_2.portrait}.css,4.theme/{_1.dark,_2.light}.css,base.css},js/,media/{aud/,vid/,img/icon.svg},schema/,_locales/{ru,ua,rs,pl,en,pt,fr,it,es,de,cn,jp}/messages.json,manifest.json} src/{pug/{0.cmp/,1.views/,2.pages/},css/{0.util/,1.cmp/{_1.icon,_2.btn,_3.card,_4.list,_5.form}.css,2.layout/_0.tab.css,3.page/{_1.landscape,_2.portrait}.css,4.theme/{_1.dark,_2.light}.css,base.css},ts/,media/{aud/,vid/,img/icon.svg},schema/,_locales/{ru,ua,rs,pl,en,pt,fr,it,es,de,cn,jp}/messages.json} build/{0.main.js,util/handler/{0.pug,1.css,2.ts}.js} src/main.ts; }

# Front dist/src (minimal)
mktouch.front_min() { mktouch "$@" dist/{html/,css/,js/,schema/,_locales/{ru,ua,rs,pl,en,pt,fr,it,es,de,cn,jp}/messages.json,manifest.json} src/{pug/,css/,ts/,schema/,_locales/{ru,ua,rs,pl,en,pt,fr,it,es,de,cn,jp}/messages.json} src/main.ts; }

# OCI configs
mktouch.oci() { mktouch "$@" OCI/{Dockerfile,docker.sh,compose.yaml,example.env}; }

# All structures
mktouch.all() { mk_git "$@"; mk_vscode "$@"; mk_docs "$@"; mk_front_full "$@"; mk_oci "$@"; }

export -f mktouch
