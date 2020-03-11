#!/bin/bash

SCRIPT_LOG_FILE="/opt/conjur-server/log/OFIRA_FILE.txt"

function wait_for_conjur_ready
{
  DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
  echo "$DATE: Starting Check Readiness" >> $SCRIPT_LOG_FILE
  #sleep 30
  DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
  echo "$DATE: Running Check Readiness" >> $SCRIPT_LOG_FILE

  while true
  do
    DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
    echo "$DATE: Iterate Check Status - Begin" >> $SCRIPT_LOG_FILE

    if [ -f /opt/conjur-server/log/conjur-server.log ]; then
      RESULT=$(grep -c StatusController /opt/conjur-server/log/conjur-server.log)
      DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
      echo "$DATE: File Exists RESULT=[$RESULT]" >> $SCRIPT_LOG_FILE
      if [ "$RESULT" = "0" ]; then
	echo "$DATE: Log File not ready - waiting" >> $SCRIPT_LOG_FILE
      else
        echo "$DATE: Log File ready - break" >> $SCRIPT_LOG_FILE
        break
      fi
    fi
    DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
    echo "$DATE: Iterate Check Readiness - Continue" >> $SCRIPT_LOG_FILE
    sleep 2

  done
  DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
  echo "$DATE: Check Status Done" >> $SCRIPT_LOG_FILE
}


function create_account_from_other_pod
{

   wait_for_conjur_ready

   DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
   echo "$DATE: Create Account From Other Pod" >> $SCRIPT_LOG_FILE
   while true
   do
     DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
     echo "$DATE: Iterate Check Status - Begin" >> $SCRIPT_LOG_FILE

     if [ -f /run/conjur-api-key/account-command ]; then
       RESULT=$(cat /run/conjur-api-key/account-command)
       DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
       echo "$DATE: Iterate Check Status RESULT=$RESULT" >> $SCRIPT_LOG_FILE
       break
     fi
     DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
     echo "$DATE: Iterate Check Status - Continue" >> $SCRIPT_LOG_FILE
     sleep 1

   done
   DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
   echo "$DATE: Check Status Done - Create Account" >> $SCRIPT_LOG_FILE

   CREATION_RESULT=$(conjurctl account create $RESULT)

   STATUS=$( echo "$CREATION_RESULT" | grep -c "already exists" )
   if [ "$STATUS"=="0" ]; then
     echo "$CREATION_RESULT" |  grep "API key" | awk '{print $5}' > /run/conjur-api-key/api-key
     DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
     echo "$DATE: Account Created" >> $SCRIPT_LOG_FILE
   fi
   rm -rf /run/conjur-api-key/account-command
}

create_account_from_other_pod &
conjurctl server > /opt/conjur-server/log/conjur-server.log

