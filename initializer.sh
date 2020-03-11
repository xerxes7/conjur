#!/bin/bash

SCRIPT_LOG_FILE="/opt/conjur-server/log/OFIRA_FILE.txt"

function create_account_from_other_pod
{
   rm -rf /run/conjur-api-key/account-command
   DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
   echo "$DATE: Create Account From Other Pod" >> $SCRIPT_LOG_FILE
   while true
   do
     DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
     echo "$DATE: Iterate Check Status - Begin" >> $SCRIPT_LOG_FILE

     if [ -f /run/conjur-api-key/account-command ]; then
       RESULT=$(cat /run/conjur-api-key/account-command)
       DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
       break
     fi
     DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
     echo "$DATE: Iterate Check Status - Continue" >> $SCRIPT_LOG_FILE
     sleep 1

   done
   DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
   echo "$DATE: Check Status Done - Create Account" >> $SCRIPT_LOG_FILE
   conjurctl account delete $RESULT
   conjurctl account create $RESULT  |  grep "API key" | awk '{print $5}' > /run/conjur-api-key/api-key
   DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
   echo "$DATE: Account Created" >> $SCRIPT_LOG_FILE
   rm -rf /run/conjur-api-key/account-command
}

create_account_from_other_pod &
conjurctl server > /opt/conjur-server/log/conjur-server.log

