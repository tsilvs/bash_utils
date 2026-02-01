#!/usr/bin/env bash

mktouch() {
	local deps=(tree)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			return 127 2>/dev/null || exit 127
		}
	done
	local paths=() created=()
	local show_tree=false dry_run=false
	local prefix=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				cat <<-EOF
				Usage: ${FUNCNAME[0]} [OPTIONS] [--path|-p] <path> [<path> ...]
				Creates directories and files for given paths.

				Options:
					-C, --prefix <dir>  Prefix all paths (git -C style)
					-t, --tree          Show tree of created paths
					-n, --dry-run       Preview only
					-h, --help          Help
				EOF
				return 0 ;;
			-C|--prefix)
				shift; [[ $# -eq 0 ]] && { echo "Error: --prefix needs arg" >&2; return 1; }
				prefix="$1"; shift ;;
			-t|--tree) show_tree=true; shift ;;
			-n|--dry-run) dry_run=true; show_tree=true; shift ;;
			--) shift; break ;;
			-*) echo "Error: unknown option $1" >&2; return 1 ;;
			*) paths+=("$1"); shift ;;
		esac
	done
	paths+=("$@")
	[[ ${#paths[@]} -eq 0 ]] && { echo "Error: no paths" >&2; return 1; }

	if [[ -n "$prefix" ]]; then
		paths=("${paths[@]/#/$prefix/}")
	fi

	if $dry_run; then
		printf '%s\n' "${paths[@]}" \
		| tree --fromfile -F --noreport --dirsfirst
		return 0
	fi

	for p in "${paths[@]}"; do
		if [[ "$p" == */ ]]; then
			mkdir -p "$p"
		else
			mkdir -p "$(dirname -- "$p")"
			touch "$p"
		fi
		created+=("$p")
	done

	$show_tree && printf '%s\n' "${created[@]}" \
		| tree --fromfile -F --noreport --dirsfirst
}

# ---- presets (compact expansions) -------------------------------

mktouch.git() {
	mktouch "$@" \
		README.md \
		LICENSE \
		TESTS.md \
		PUBLISH.md \
		CONTRIBUTING.md \
		CODE_OF_CONDUCT.md \
		.gitignore \
		.github/FUNDING.yml
}

mktouch.vscode() { mktouch "$@" .vscode/{extensions.json,json.code-snippets,markdown.code-snippets,settings.json}; }

mktouch.docs() {
	mktouch "$@" doc/dev/{0.std/{README.md,core/,front/{html,pug,css,ts,js}/,back/,data/,infra/},1.req/{README.md,{1.US,2.UC,3.BRD,4.SDD}/},2.plan/README.md}
}

# ---- front split ------------------------------------------------

mktouch.front.lc() {
	mktouch "$@" {dist,src}/_locales/{ru,ua,rs,pl,en,pt,fr,it,es,de,cn,jp}/messages.json
}

mktouch.front.css() {
	mktouch "$@" {dist,src}/css/{0.util/,1.cmp/,2.layout/,3.page/,4.theme/,base.css}
}

mktouch.front.html() {
	mktouch "$@" dist/html/pages/index.html src/pug/{0.cmp/.ph.cmp.pug,1.views/.ph.view.pug,2.pages/index.pug}
}

mktouch.front.ts() {
	mktouch "$@" dist/js/main.js src/ts/main.ts
}

mktouch.front.media() {
	mktouch "$@" {dist,src}/media/{aud/.ph,vid/.ph,img/icon.svg}
}

mktouch.front.schema() {
	mktouch "$@" {dist,src}/schema/.ph.schema.json
}

mktouch.front.full() {
	mktouch.front.lc "$@"
	mktouch.front.css "$@"
	mktouch.front.html "$@"
	mktouch.front.ts "$@"
	mktouch.front.media "$@"
	mktouch.front.schema "$@"
	mktouch "$@" dist/manifest.json
}

mktouch.oci() {
	mktouch "$@" OCI/{Dockerfile,docker.sh,compose.yaml,example.env}
}

export -f mktouch
export -f mktouch.git
export -f mktouch.vscode
export -f mktouch.docs
export -f mktouch.oci
export -f mktouch.front.lc
export -f mktouch.front.css
export -f mktouch.front.html
export -f mktouch.front.ts
export -f mktouch.front.media
export -f mktouch.front.schema
export -f mktouch.front.full
