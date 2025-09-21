#!/usr/bin/env bash

# for file in "${files[@]}"; do
# 	output="${file%.pdf}.wmk.pdf"
# 	watermark grid "$file" "WATERMARK" -o 0.2 -a 45 -ts 50 -tc "#AAAAAA" -s "$output"
# done

# for file in "${files[@]}"; do
# 	rm "${file}"
# 	rm "${file%.pdf}.flat.pdf"
# done

# for file in "${files[@]}"; do
# 	gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile="${file%.pdf}.flat.pdf" "$file"
# done

# for file in "${files[@]}"; do
# 	dir="$(dirname "$file")"
# 	base="$(basename "${file%.pdf}")"
# 	output_wmk="${dir}/${base}.wmk.pdf"
# 	output_flat="${dir}/${base}.wmk.flat.pdf"

# 	# Generate watermark PDF, overwrite if exists
# 	watermark grid "$file" "WATERMARK" -o 0.2 -a 45 -ts 50 -tc "#AAAAAA" -s "$output_wmk"

# 	# Convert pages to PNG images in same directory with original filename prefix, overwrite images if exist
# 	gs -dNOPAUSE -dBATCH -sDEVICE=png16m -r300 -sOutputFile="${dir}/${base}_tmp_page_%03d.png" "$output_wmk"

# 	# Convert PNG images back to single flattened PDF, overwrite if exists
# 	magick convert "${dir}/${base}_tmp_page_"*.png "$output_flat"
# 	mkdir -p ~/Desktop/upload
# 	cp "$output_flat" ~/Desktop/upload

# 	# Clean up temporary images
# 	rm -f "${dir}/${base}_tmp_page_"*.png
# done