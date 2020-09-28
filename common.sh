#!/usr/bin/env bash

load-config() {
	local config=$1
	local exit_on_error=${2:-false}
	[ -f "$1" ] || {
		! $exit_on_error && return 1 || {
			echo "This is a fatal error!"
			exit 1
		}
	}
	local tmp=`mktemp`
	{ PS4=" "; set -x; source $config; } &> $tmp
	{ set +x; } 2>&-
	sed '/^  source/d; /^    /d;/CLIENT_SECRET/d;s/=/: /g' $tmp
	echo "These variables was read from \"$config\" file."
}

get-TOKEN() {
	local error=false 
	! $USE_BASIC_AUTH && {
		TOKEN=$(curl -X POST \
			"$SSO_URL/realms/$REALM/protocol/openid-connect/token" \
			-H 'Content-Type: application/x-www-form-urlencoded' \
			-d 'grant_type=client_credentials' \
			-d "client_secret=$CLIENT_SECRET" \
			-d "client_id=$CLIENT_ID" 2> $TMP_DIR/$FUNCNAME.log | jq -r '.access_token') || error=true
	} || {
	  TOKEN=$(curl -X POST \
		  "$SSO_URL/realms/$REALM/protocol/openid-connect/token" \
		  -H 'Content-Type: application/x-www-form-urlencoded' \
		  -H "Authorization: Basic $(echo -n $CLIENT_ID:$CLIENT_SECRET | base64)" \
		  -d 'grant_type=client_credentials' 2> $TMP_DIR/$FUNCNAME.log | jq -r '.access_token') || error=true
	}
	! $error || {
		echo "$FUNCNAME returns error:"
		cat $TMP_DIR/$FUNCNAME.log
	}
}

function create-user() {
	local user_name=$1
	local password=$2
	local add_cmd=$(cat <<-EOF
		curl -X POST \
			"$SSO_URL/admin/realms/$REALM/users" \
			-H 'Content-Type: application/json' \
			-H "Authorization: Bearer $TOKEN" \
			--data-raw '{
				"username": "$user_name",
				"enabled": true,
				"credentials": [{"type":"password","value":"$password","temporary":false}]
				}' 2> /dev/null
		EOF
		)
	eval "$add_cmd"
}

function delete-user() {
	local user_id=$1
	curl -X DELETE "$SSO_URL/admin/realms/$REALM/users/$user_id" \
		-H 'Content-Type: application/json' \
		-H "Authorization: Bearer $TOKEN" 2> /dev/null
}

function get-user-id() {
	local user_name=$1
	curl -X GET \
		"$SSO_URL/admin/realms/$REALM/users?briefRepresentation=true&search=$user_name" \
		-H 'Content-Type: application/json' \
		-H "Authorization: Bearer $TOKEN" 2> /dev/null |
		jq -r '.[0].id'
}

function get-user-token() {
	local client=$1
	local user_name=$2
	local password=$3
	local added_params=""
	[ "$client" = "admin-cli" ] || added_params="-d "client_secret=$CLIENT_SECRET""
	curl -X POST \
		"$SSO_URL/realms/$REALM/protocol/openid-connect/token" \
		-H 'Content-type: application/x-www-form-urlencoded' \
		-d "client_id=$client" $added_params \
		-d 'grant_type=password' \
		-d "username=$user_name" \
		-d "password=$password" 2> /dev/null |
		jq -r '.access_token'
}

echo "Base dir is \"$PWD\"."
echo "Configured variables (excluding sensitive): "
config=./config
load-config $config || {
	config=$config.sample
	load-config $config true || {
		echo "Fatal: file \"$PWD/$config\" has errors!"
		exit 1
	} 
}
mkdir -p "$TMP_DIR"
LOG_FILE=$TMP_DIR/$LOG_FILE
CREATED_USERS_FILE=$TMP_DIR/$CREATED_USERS_FILE
TOKENS_FILE=$TMP_DIR/$TOKENS_FILE
echo "Generated files adjusted to be created in \"$TMP_DIR\" directory."
