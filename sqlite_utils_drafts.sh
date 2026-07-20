
# DB=~/.local/share/opencode/opencode.db
# OUT=pages/0.Tech/CS/Data/AI/Teams/Anthropic/Conflict_of_Interest/README.md
# mkdir -p "$(dirname "$OUT")"
# sqlite3 "$DB" "select data from part where data like '{_type___reasoning_%Distributed AI Research Institute%'" \
#   | jq -r '.text' \
#   | grep -vi '^let me' \
#   > "$OUT"
# echo "rc=$? lines=$(wc -l < "$OUT") bytes=$(wc -c < "$OUT")"
# head -3 "$OUT"
