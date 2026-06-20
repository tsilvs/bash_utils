#!/usr/bin/env bash

# ─── CLI Framework ───────────────────────────────────────────────────────────
# Option metadata utilities, usage builders, and completion registration.

# ── Build usage string from metadata arrays ────────────────────────────────────
# Convention: _<FN_PREFIX>_OPTS_{SHORT,LONG,ARG,DESC}
# Usage: eval "$(build_usage "FFMPEG_VIDEO_SPEED" "$fn" "description" "extra_help")"
build_usage() {
	local prefix="$1" fn="$2" desc="$3" extra_help="$4"
	local var_short="${prefix}_OPTS_SHORT[@]"
	local var_long="${prefix}_OPTS_LONG[@]"
	local var_arg="${prefix}_OPTS_ARG[@]"
	local var_desc="${prefix}_OPTS_DESC[@]"
	local short_arr=("${!var_short}")
	local long_arr=("${!var_long}")
	local arg_arr=("${!var_arg}")
	local desc_arr=("${!var_desc}")
	local opts_block="" line i

	for ((i = 0; i < ${#short_arr[@]}; i++)); do
		local sig="${short_arr[$i]}, ${long_arr[$i]}${arg_arr[$i]:+ ${arg_arr[$i]}}"
		printf -v line '\t%-32s%s\n' "$sig" "${desc_arr[$i]}"
		opts_block+="$line"
	done

	cat <<-EOF
		    local usage="Usage: $fn [OPTIONS] $desc
		    $extra_help
		    Options:
		    $opts_block"
	EOF
}

# ── Register bash completion for a function ────────────────────────────────────
# Usage: register_completion "fn" "FN_PREFIX"
# Generates _fn_complete() + complete -F _fn_complete fn
register_completion() {
	local fn="$1" prefix="$2"
	local fn_clean="${fn//./_}"
	eval "
    _${fn_clean}_complete() {
        local cur=\"\${COMP_WORDS[COMP_CWORD]}\"
        local all_opts=(\"\${${prefix}_OPTS_SHORT[@]}\" \"\${${prefix}_OPTS_LONG[@]}\")
        case \"\$cur\" in
        -*) mapfile -t COMPREPLY < <(compgen -W \"\${all_opts[*]}\" -- \"\$cur\") ;;
        *)  mapfile -t COMPREPLY < <(compgen -f -- \"\$cur\") ;;
        esac
    }
    complete -F _${fn_clean}_complete $fn
    "
}

export -f build_usage register_completion

# ── Register simple bash completion (no metadata arrays needed) ──────────────────
# Usage: register_simple_completion "fn" ["-o" "--other-opt" ...]
# Auto-adds -h/--help, generates file completion for non-flag args
register_simple_completion() {
	local fn="$1" fn_clean="${fn//./_}"
	shift
	local extra_opts=("$@")
	local all_opts='-h --help'
	for o in "${extra_opts[@]}"; do [[ -n "$o" ]] && all_opts+=" $o"; done
	eval "
    _${fn_clean}_complete() {
        local cur=\"\${COMP_WORDS[COMP_CWORD]}\"
        case \"\$cur\" in
        -*) mapfile -t COMPREPLY < <(compgen -W \"${all_opts}\" -- \"\$cur\") ;;
        *)  mapfile -t COMPREPLY < <(compgen -f -- \"\$cur\") ;;
        esac
    }
    complete -F _${fn_clean}_complete $fn
    "
}

export -f register_simple_completion
