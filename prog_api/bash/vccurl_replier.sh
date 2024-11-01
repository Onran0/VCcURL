#!/usr/bin/env bash

function processCurlRequest {
	local req_id=$(basename "$1")

	echo "Processing cURL request with ID $req_id"

	local raw_resp_path=$raw_resp_dir/$req_id
	local resp_path=$resp_dir/$req_id

	local args=$(cat "$1")

	rm "$1"

	local eval_output=$(eval "curl $args")

	if ! [ -e "$raw_resp_path" ]; then
		echo "$eval_output" > "$resp_path"
	else
		cp "$raw_resp_path" "$resp_path"
		rm "$raw_resp_path"
	fi
}

function processDeleteRequest {
	echo "Processing file delete request with ID $(basename "$1")"

	local file_to_delete="$ipc_dir/$(cat "$1")"

	if [ -e "$file_to_delete" ]; then
		rm -r "$file_to_delete"
	fi

	rm "$1"
}

ipc_dir=$(dirname "$0")/export/curl/internal/ipc

req_dir=$ipc_dir/requests
resp_dir=$ipc_dir/responses
raw_resp_dir=$ipc_dir/raw_responses
del_dir=$ipc_dir/delete

if [ -e "$ipc_dir" ]; then
	rm -r "$ipc_dir" 2> /dev/null
fi

mkdir -p "$ipc_dir" 2> /dev/null

mkdir "$req_dir" 2> /dev/null
mkdir "$resp_dir" 2> /dev/null
mkdir "$raw_resp_dir" 2> /dev/null
mkdir "$del_dir" 2> /dev/null

cd "$ipc_dir"

while true; do
	for curl_req in "$req_dir"/*; do
		[[ -e $curl_req ]] || continue

		processCurlRequest "$curl_req"
	done

	for del_req in "$del_dir"/*; do
		[[ -e $del_req ]] || continue

		processDeleteRequest "$del_req"
	done

	sleep .5
done