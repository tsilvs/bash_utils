#!/bin/bash

# ffmpeg.x2.cmp() {
# 	ffmpeg -i "$input" -vf "setpts=0.5*PTS" -filter:a "atempo=2.0" -vcodec libx265 -crf 28 "$output.mkv"
# 	return $?
# }

# ffmpeg.get.wav() {
# 	ffmpeg -y -i "$output.mkv" -ar 16000 -ac 2 -c:a pcm_s16le "$output.wav"
# 	return $?
# }

# ffmpeg.get.srt() {
# 	ffmpeg -i "$input" -map 0:s:0 -c:s srt -f srt -y "$output.srt"
# 	return $?
# }

# for input in $videofiles; do
# 	output="${input%.*}.cmp.x2"
# 	ffmpeg -i "$input" -vf "setpts=0.5*PTS" -filter:a "atempo=2.0" -vcodec libx265 -crf 28 "$output.mkv"
# 	ffmpeg -y -i "$output.mkv" -ar 16000 -ac 2 -c:a pcm_s16le "$output.wav"
# 	/mnt/data/bin/whisper/bin/main -m /mnt/data/models/whisper/ggml-large-v3-turbo.bin -t 12 -l ru -f "$output.wav" -osrt -otxt -of "$output"
# done
