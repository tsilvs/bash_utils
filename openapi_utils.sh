#!/usr/bin/env bash

# WARN: WIP!!!

openapi.filter() {
	local deps=(yq jq)
	for d in "${deps[@]}"; do
		command -v "$d" >/dev/null 2>&1 || {
			echo "Error: dependency missing: $d" >&2
			return 127 2>/dev/null || exit 127
		}
	done

	local dryrun=0
	local showhelp=0
	local input=""
	local output=""

	local usage="$(cat <<-EOF
		Usage:
			${FUNCNAME[0]} [OPTIONS] [-i] <INPUT> [-o] [<OUTPUT>] [-p] [PATHS...]
		Filter OpenAPI spec by paths, keeping only referenced schemas.
		
		Options:
			[-i, --input] INPUT         Input OpenAPI YAML file.
			[-o, --output] OUTPUT       (Optional) Output filtered YAML file. If not specified - prints modified YAML to stdout.
			[-p, --paths] PATHS         Paths to include (optional, can use --paths).
			-n, --dry-run               Show what would be done without executing.
			-h, --help                  Show help.
		
		Without markers parameter indexed by relative position.
		With markers - in any order.
		
		Examples:
			${FUNCNAME[0]} -i openapi.yaml -o filtered.yaml /users /posts
			${FUNCNAME[0]} -n -i openapi.yaml /users
	EOF
	)"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help) showhelp=1; shift ;;
			-n|--dry-run) dryrun=1; shift ;;
			# TODO: Verify if this won't break anything
			--)
				shift
				break
				;;
			# TODO: Verify if this won't break anything
			-*)
				echo "Error: Unknown option: $1" >&2
				echo "$usage" >&2
				return 1
				;;
			# TODO: Verify if this won't break anything
			*)
				break
				;;
		esac
	done

	(( showhelp )) && { echo "$usage"; return 0; }

	local -a paths=()
	local use_markers=0

	# First pass: check if any markers are used
	for arg in "$@"; do
		case "$arg" in
			-i|--input|-o|--output|-p|--paths) use_markers=1; break ;;
		esac
	done

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help) showhelp=1; shift ;;
			-n|--dry-run) dryrun=1; shift ;;
			-i|--input)
				input="$2"
				shift 2
				;;
			-o|--output)
				output="$2"
				shift 2
				;;
			-p|--paths)
				shift
				while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; do
					paths+=("$1")
					shift
				done
				;;
			--)
				shift
				break
				;;
			-*)
				echo "Error: Unknown option: $1" >&2
				echo "$usage" >&2
				return 1
				;;
			# TODO: Verify algorithm logic
			*)
				if (( use_markers )); then
					# With markers, positional args after options are paths
					paths+=("$1")
					shift
				else
					# Without markers: positional by index
					break
				fi
				;;
		esac
	done

	(( showhelp )) && { echo "$usage"; return 0; }

	# Handle positional arguments (when no markers used)
	if (( ! use_markers )); then
		# Positional: INPUT [OUTPUT] [PATHS...]
		if [[ $# -lt 1 ]]; then
			echo "Error: Missing required argument: INPUT file" >&2
			echo "$usage" >&2
			return 1
		fi
		input="$1"
		shift
		if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; then
			output="$1"
			shift
		fi
		# Remaining args are paths
		while [[ $# -gt 0 ]]; do
			paths+=("$1")
			shift
		done
	fi

	# Validate input
	[[ -z "$input" ]] && {
		echo "Error: Missing required argument: INPUT file" >&2
		echo "$usage" >&2
		return 1
	}

	[[ ! -f "$input" ]] && {
		echo "Error: Input file not found: $input" >&2
		return 1
	}

	[[ ! -r "$input" ]] && {
		echo "Error: Cannot read input file: $input" >&2
		return 1
	}

	# Validate output directory if output specified
	if [[ -n "$output" ]]; then
		local outdir
		outdir="$(dirname "$output")"
		[[ ! -d "$outdir" ]] && {
			echo "Error: Output directory does not exist: $outdir" >&2
			return 1
		}
		[[ ! -w "$outdir" ]] && {
			echo "Error: Cannot write to output directory: $outdir" >&2
			return 1
		}
	fi

	# Validate paths
	if [[ ${#paths[@]} -eq 0 ]]; then
		echo "Error: No paths specified to filter" >&2
		return 1
	fi

	local paths_json
	paths_json="$(printf '%s\n' "${paths[@]}" | jq -R . | jq -s .)" || {
		echo "Error: Failed to process paths with jq" >&2
		return 1
	}

	run_filter() {
		if [[ -n "$output" ]]; then
			yq eval "
				def refs:
					.. | select(has(\"\\\$ref\")) | .\"\\\$ref\" |
					select(test(\"^#/components/schemas/\")) |
					sub(\"^#/components/schemas/\"; \"\");

				. as \$doc
				| (\$doc.paths
					| with_entries(select(.key as \$k | $paths_json | index(\$k))))
					as \$filtered_paths
				| (\$filtered_paths | refs | unique) as \$schemas
				| \$doc
				| .paths = \$filtered_paths
				| .components.schemas |=
						with_entries(select(.key as \$k | \$schemas | index(\$k)))
			" "$input" > "$output"
		else
			yq eval "
				def refs:
					.. | select(has(\"\\\$ref\")) | .\"\\\$ref\" |
					select(test(\"^#/components/schemas/\")) |
					sub(\"^#/components/schemas/\"; \"\");

				. as \$doc
				| (\$doc.paths
					| with_entries(select(.key as \$k | $paths_json | index(\$k))))
					as \$filtered_paths
				| (\$filtered_paths | refs | unique) as \$schemas
				| \$doc
				| .paths = \$filtered_paths
				| .components.schemas |=
						with_entries(select(.key as \$k | \$schemas | index(\$k)))
			" "$input"
		fi
	}

	if (( dryrun )); then
		echo "DRY-RUN: Would filter '$input'"
		if [[ -n "$output" ]]; then
			echo "DRY-RUN: Output -> '$output'"
		else
			echo "DRY-RUN: Output -> stdout"
		fi
		echo "DRY-RUN: Paths to include:"
		printf '%s\n' "${paths[@]}" | sed 's/^/  - /'
		return 0
	else
		run_filter || {
			echo "Error: Failed to filter OpenAPI spec" >&2
			return 1
		}
		[[ -n "$output" ]] && echo "Filtered spec written to: $output"
	fi
}

export -f openapi.filter
