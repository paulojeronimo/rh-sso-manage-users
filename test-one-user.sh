#!/usr/bin/env bash
set -euo pipefail
cd "`dirname "$0"`"
source ./common.sh

USER_NUMBER=${USER_NUMBER:-$(( NB_OF_USERS + 1 ))}
USER_NAME=$(printf "${USER_PREFIX}-%0${LEADING_ZEROS}d" $USER_NUMBER)
TOKEN_CLIENT_ID=${TOKEN_CLIENT_ID:-$CLIENT_ID}
TOKEN_FILE=$TMP_DIR/`basename "$0" .sh`.csv
DELETE_USER=${DELETE_USER:-true}
PASSWORD=$(openssl rand -base64 16 | colrm $(( PASSWORD_SIZE + 1 )))

_delete-user() {
	local user_id=$1
	local proceed=$2
	! $2 || echo -n "Deleting user ... "
	delete-user $1 && { ! $2 || echo ok; }
}

get-TOKEN
echo -e "\nOne user test started!"
echo -n "Adding user \"$USER_NAME\" ... "
create-user $USER_NAME $PASSWORD && echo ok
user_id=`get-user-id $USER_NAME`
echo "Recovered user id: $user_id"
echo -n "Getting token for client \"$TOKEN_CLIENT_ID\" ... "
user_token=$(get-user-token $TOKEN_CLIENT_ID $USER_NAME $PASSWORD) && echo ok || {
		echo "Failed to get the token!"
		_delete-user $USER_NAME true
		exit 1
	}
echo "ID,Username,Password,Token (for $TOKEN_CLIENT_ID)" > $TOKEN_FILE
echo "$user_id,$USER_NAME,$PASSWORD,$user_token" >> $TOKEN_FILE
echo "User token saved in \"$TOKEN_FILE\"!"
_delete-user $user_id $DELETE_USER
echo "Test completed successfuly!"
