#!/usr/bin/env bash

# youtube.subs.all.delete() {
# 	if [ -z "$GOOGLE_ACCESS_TOKEN" ]; then
# 		echo "Error: ACCESS_TOKEN environment variable is not set."
# 		return 1
# 	fi

# 	nextPageToken=""
# 	while : ; do
# 		response=$(curl -s -G \
# 			--data-urlencode "part=id" \
# 			--data-urlencode "mine=true" \
# 			--data-urlencode "maxResults=50" \
# 			--data-urlencode "pageToken=$nextPageToken" \
# 			"https://www.googleapis.com/youtube/v3/subscriptions" \
# 			-H "Authorization: Bearer $GOOGLE_ACCESS_TOKEN")

# 		subscription_ids=$(echo "$response" | jq -r '.items[].id')
# 		for id in $subscription_ids; do
# 			curl -s -X DELETE \
# 				"https://www.googleapis.com/youtube/v3/subscriptions?id=$id" \
# 				-H "Authorization: Bearer $GOOGLE_ACCESS_TOKEN"
# 			echo "Deleted subscription $id"
# 		done

# 		nextPageToken=$(echo "$response" | jq -r '.nextPageToken // empty')
# 		[ -z "$nextPageToken" ] && break
# 	done
# }