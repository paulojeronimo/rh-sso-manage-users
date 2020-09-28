#!/usr/bin/env bash
set -euo pipefail
cd "`dirname "$0"`"
source ./common.sh

get-TOKEN
echo "Execution at: `date`" > $LOG_FILE
echo "Deleting users (each \".\" represents $NB_OF_USER_PER_DOT users) ..."
count=0
while IFS= read -r user
do
	user_name=$(echo -n $user | cut -d, -f1)
	user_id=$(get-user-id $user_name)
	delete-user $user_id
	(( count += 1 ))
	! [ $(( count % $NB_OF_USER_PER_DOT )) = 0 ] || echo -n "."
done < <(tail -n +2 $CREATED_USERS_FILE)
echo
echo -e "Number of users deleted: $count." | tee -a $LOG_FILE
