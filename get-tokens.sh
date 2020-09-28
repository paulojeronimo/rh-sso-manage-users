#!/usr/bin/env bash
set -euo pipefail
cd "`dirname "$0"`"
source ./common.sh

get-TOKEN
echo "Execution at: `date`" > $LOG_FILE
echo "Getting users tokens (each \".\" represents $NB_OF_USER_PER_DOT users) ..."
echo "Username,Token (for \"$CLIENT_ID\" client)" > $TOKENS_FILE
echo "Adding users (each \".\" represents $NB_OF_USER_PER_DOT users) ..."
count=0
while IFS= read -r user
do
	user_name=$(echo -n $user | cut -d, -f1)
	password=$(echo -n $user | cut -d, -f2)
	user_token=$(get-user-token $CLIENT_ID $user_name $password)
 	(( count += 1 ))
	echo "$user_name,$user_token" >> $TOKENS_FILE
	! [ $(( count % $NB_OF_USER_PER_DOT )) = 0 ] || echo -n "."
done < <(tail -n +2 $CREATED_USERS_FILE)
echo -e "\nFile \"$TOKENS_FILE\" created!"
echo -e "Number of tokens created: $count." | tee -a $LOG_FILE
