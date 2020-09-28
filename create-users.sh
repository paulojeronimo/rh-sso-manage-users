#!/usr/bin/env bash
set -euo pipefail
cd "`dirname "$0"`"
source ./common.sh

get-TOKEN
echo "Execution at: `date`" > $LOG_FILE
echo "Username,Password" > $CREATED_USERS_FILE
echo "Adding users (each \".\" represents $NB_OF_USER_PER_DOT users) ..."
count=1
while (( count <= NB_OF_USERS ))
do
	username=$(printf "${USER_PREFIX}-%0${LEADING_ZEROS}d" $count)
	password=$(openssl rand -base64 16 | colrm $(( PASSWORD_SIZE + 1)) | tr + k)
	create-user $username $password
	! [ $(( count % $NB_OF_USER_PER_DOT )) = 0 ] || echo -n "."
	echo "$username,$password" >> $CREATED_USERS_FILE
	(( count += 1 ))
done
echo -e "\nFile \"$CREATED_USERS_FILE\" created!"
echo "Number of users created: $(( count - 1 ))." | tee -a $LOG_FILE
