#!/usr/bin/env bash

# md.index.gen() {
# 	local dir="$1"
# 	local index_file_name="_index.md"
# 	local index_file="${dir}/${index_file_name}"
	
# 	# Find markdown files excluding ${index_file_name}
# 	local md_files=()
# 	while IFS= read -r -d $'\0' file; do
# 		md_files+=("$(basename "$file")")
# 	done < <(find "$dir" -maxdepth 1 -type f -name "*.md" ! -name "${index_file_name}" -print0 | sort -z)

# 	# Find subdirectories having ${index_file_name}
# 	local subdirs=()
# 	while IFS= read -r -d $'\0' subdir; do
# 		if [[ -f "${subdir}/${index_file_name}" ]]; then
# 			subdirs+=("$(basename "$subdir")/${index_file_name}")
# 		fi
# 	done < <(find "$dir" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)

# 	# Write ${index_file_name}
# 	{
# 		for file in "${md_files[@]}"; do
# 			echo "+ [${file%.*}](./${file})"
# 		done
# 		for sub in "${subdirs[@]}"; do
# 			echo "+ [${sub}](${sub})"
# 		done
# 	} > "$index_file"
# }

# export -f md.index.gen

# # Recursively generate index in each directory
# find . -type d -exec bash -c 'generate_index "$0"' {} \;

# tree -i -f -P 'TODO.md' --prune --noreport -n --filesfirst | grep --color=none -E 'TODO.md' | perl -pe 's|./([[:alnum:]./_-]+)/TODO\.md|+ [$1](./$1/TODO.md)|'

