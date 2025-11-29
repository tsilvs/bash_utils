#!/usr/bin/env bash

#!/bin/bash

csv.merge() {
	local pattern join_col output=""
	
	while [[ $# -gt 0 ]]; do
		case $1 in
			-p|--pattern) pattern="$2"; shift 2 ;;
			-j|--joincol) join_col="$2"; shift 2 ;;
			-o|--output) output="$2"; shift 2 ;;
			*) echo "Unknown: $1" >&2; return 1 ;;
		esac
	done
	
	[[ -z "$pattern" ]] && { echo "Pattern required" >&2; return 1; }
	[[ -z "$join_col" ]] && { echo "Join column required" >&2; return 1; }
	
	local temp_db=$(mktemp --suffix=.db)
	trap "rm -f $temp_db" EXIT
	
	# Load all CSVs into temp table
	sqlite3 "$temp_db" <<SQL
.mode csv
.import '|cat $pattern' data
SQL
	
	local cols=$(sqlite3 "$temp_db" "PRAGMA table_info(data);" | \
		awk -F'|' -v j="$join_col" '$2 != j {printf "MAX(\"%s\") as \"%s\",", $2, $2}' | \
		sed 's/,$//')
	
	local query="SELECT $cols, \"$join_col\" FROM data GROUP BY \"$join_col\";"
	
	if [[ -n "$output" ]]; then
		sqlite3 -header -csv "$temp_db" "$query" > "$output"
	else
		sqlite3 -header -csv "$temp_db" "$query"
	fi
}

csv.col.split() {
	local input output="" col sep left_name right_name
	local keep_orig=false delim_to="" split_from="left" occurrence=1
	
	while [[ $# -gt 0 ]]; do
		case $1 in
			-i|--input) input="$2"; shift 2 ;;
			-o|--output) output="$2"; shift 2 ;;
			-c|--column) col="$2"; shift 2 ;;
			-s|--separator) sep="$2"; shift 2 ;;
			-l|--left-name) left_name="$2"; shift 2 ;;
			-r|--right-name) right_name="$2"; shift 2 ;;
			-k|--keep-original) keep_orig=true; shift ;;
			-d|--delimiter-to) delim_to="$2"; shift 2 ;; 
			-f|--from) split_from="$2"; shift 2 ;; 
			-n|--occurrence) occurrence="$2"; shift 2 ;;
			*) echo "Unknown: $1" >&2; return 1 ;;
		esac
	done
	
	[[ -z "$input" ]] && { echo "Input required" >&2; return 1; }
	[[ -z "$col" ]] && { echo "Column required" >&2; return 1; }
	[[ -z "$sep" ]] && { echo "Separator required" >&2; return 1; }
	[[ -z "$left_name" ]] && left_name="${col}_left"
	[[ -z "$right_name" ]] && right_name="${col}_right"
	[[ -z "$delim_to" ]] && delim_to="none"
	
	local temp_db=$(mktemp --suffix=.db)
	trap "rm -f $temp_db" EXIT
	
	# 1. Import CSV to SQLite
	sqlite3 "$temp_db" <<SQL
.mode csv
.import '$input' data
SQL
	
	# 2. Build Expressions
	local left_expr right_expr delim_expr="" pos_expr
	
	if [[ "$split_from" == "right" ]]; then
		# Logic: Find last separator by Reversing string, finding first separator, then calculating index
		# NOTE: This relies on the pipe character '|' not being in your data.
		pos_expr="LENGTH(\"$col\") - INSTR(REPLACE(REVERSE(\"$col\"), REVERSE('$sep'), '|'), '|') + 1"
	else
		pos_expr="INSTR(\"$col\", '$sep')"
	fi
	
	case "$delim_to" in
		none)
			left_expr="SUBSTR(\"$col\", 1, $pos_expr - 1)"
			right_expr="SUBSTR(\"$col\", $pos_expr + LENGTH('$sep'))"
			;;
		left)
			left_expr="SUBSTR(\"$col\", 1, $pos_expr + LENGTH('$sep') - 1)"
			right_expr="SUBSTR(\"$col\", $pos_expr + LENGTH('$sep'))"
			;;
		right)
			left_expr="SUBSTR(\"$col\", 1, $pos_expr - 1)"
			right_expr="SUBSTR(\"$col\", $pos_expr)"
			;;
		both)
			left_expr="SUBSTR(\"$col\", 1, $pos_expr + LENGTH('$sep') - 1)"
			right_expr="SUBSTR(\"$col\", $pos_expr)"
			;;
		separate)
			left_expr="SUBSTR(\"$col\", 1, $pos_expr - 1)"
			right_expr="SUBSTR(\"$col\", $pos_expr + LENGTH('$sep'))"
			delim_expr=", '$sep' as \"${col}_delim\""
			;;
	esac
	
	# 3. Build Column List
	local select_cols=""
	local cols=$(sqlite3 "$temp_db" "PRAGMA table_info(data);" | awk -F'|' '{print $2}')
	
	while IFS= read -r c; do
		if [[ "$c" == "$col" ]]; then
			if $keep_orig; then
				select_cols+="\"$c\", "
			fi
			select_cols+="$left_expr as \"$left_name\", $right_expr as \"$right_name\"$delim_expr, "
		else
			select_cols+="\"$c\", "
		fi
	done <<< "$cols"
	select_cols=${select_cols%, }
	
	local query="SELECT $select_cols FROM data;"
	
	# 4. Execute
	# Helper to run query via Python (for REVERSE support) or SQLite directly
	run_query() {
		if [[ "$split_from" == "right" ]]; then
			if ! command -v python3 &>/dev/null; then
				echo "Error: --from right requires python3 installed to simulate REVERSE function." >&2
				return 1
			fi
			# Python shim to inject REVERSE function
			QUERY="$query" DB="$temp_db" python3 -c '
import sqlite3, csv, os, sys
conn = sqlite3.connect(os.environ["DB"])
# Define the missing REVERSE function
conn.create_function("REVERSE", 1, lambda s: s[::-1] if s else "")
cursor = conn.cursor()
cursor.execute(os.environ["QUERY"])
writer = csv.writer(sys.stdout)
writer.writerow([d[0] for d in cursor.description])
writer.writerows(cursor)
'
		else
			sqlite3 -header -csv "$temp_db" "$query"
		fi
	}

	if [[ -n "$output" ]]; then
		run_query > "$output"
	else
		run_query
	fi
}

# $> csv.col.split --input merged.csv --column "Primary Email" --keep-original --separator "@" --from right --occurrence 1 --left-name "username" --right-name "full domain" > merged.sep.csv
# $> csv.col.split --input merged.sep.csv --column "full domain" --keep-original --separator "." --from right --occurrence 1 --left-name "domain" --right-name "tld" | sponge merged.sep.csv
# $> csv.col.split --input merged.sep.csv --column "domain" --keep-original --separator "." --from left --occurrence 1 --left-name "domain sub" --right-name "domain core" | sponge merged.sep.csv

csv.row.template() {
	local input output="" template="" sep=","
	
	while [[ $# -gt 0 ]]; do
		case $1 in
			-i|--input) input="$2"; shift 2 ;;
			-o|--output) output="$2"; shift 2 ;;
			-t|--template) template="$2"; shift 2 ;;
			-s|--separator) sep="$2"; shift 2 ;;
			*) echo "Unknown argument: $1" >&2; return 1 ;;
		esac
	done

	[[ -z "$input" ]] && { echo "Input file required (-i)" >&2; return 1; }
	[[ -z "$template" ]] && { echo "Template string required (-t)" >&2; return 1; }

	local expanded_template
	printf -v expanded_template "%b" "$template"

	export CSV_INPUT="$input"
	export CSV_SEP="$sep"
	export CSV_TEMPLATE="$expanded_template"

	local script='
import csv, os, re, sys, signal

signal.signal(signal.SIGPIPE, signal.SIG_DFL)

input_file = os.environ["CSV_INPUT"]
delimiter = os.environ["CSV_SEP"]
template = os.environ["CSV_TEMPLATE"]

pattern = re.compile(r"\{\{\.(.*?)\}\}")

try:
	with open(input_file, mode="r", encoding="utf-8-sig", newline="") as f:
		reader = csv.DictReader(f, delimiter=delimiter)
		
		for i, row in enumerate(reader):
			def replace_match(match):
				col_name = match.group(1)
				# Handle missing columns gracefully or strictly
				if col_name not in row:
					sys.stderr.write(f"Error: Row {i+2}: Column \"{col_name}\" not found.\n")
					sys.exit(1)
				return row[col_name]

			sys.stdout.write(pattern.sub(replace_match, template))

except FileNotFoundError:
	sys.stderr.write(f"Error: File {input_file} not found.\n")
	sys.exit(1)
except Exception as e:
	sys.stderr.write(f"Error: {str(e)}\n")
	sys.exit(1)
'

	if [[ -n "$output" ]]; then
		python3 -c "$script" > "$output"
	else
		python3 -c "$script"
	fi
}

# csv.row.template --input merged.sep.csv --template 'name="{{.Custom 1}}.{{.Custom 2}}.{{.Custom 3}}.{{.Custom 4}}"\nenabled="yes"\ntype="17"\naction="Move to folder"\nactionValue="imap://username%40domain@imap.domain/Msg/{{.Custom 1}}/{{.Custom 2}}/{{.Custom 3}}/{{.Custom 4}}"\ncondition="AND (from,contains,{{.Primary Email}})"'

