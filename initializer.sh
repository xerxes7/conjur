#!/bin/bash

SCRIPT_LOG_FILE="/opt/conjur-server/log/OFIRA_FILE.txt"

function recreate_account
{
  DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
  echo "$DATE: Starting Check Status" >> $SCRIPT_LOG_FILE
  #sleep 30
  DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
  echo "$DATE: Running Check Status" >> $SCRIPT_LOG_FILE

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
    echo "$DATE: Iterate Check Status - Continue" >> $SCRIPT_LOG_FILE
    sleep 2

  done
  DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
  echo "$DATE: Check Status Done - Create Account" >> $SCRIPT_LOG_FILE
  conjurctl account delete myaccount
  conjurctl account create myaccount  |  grep "API key" | awk '{print $5}' > /run/conjur-api-key/accountFile
  DATE=$(date +"%Y-%m-%d %H:%M:%S,%3N")
  echo "$DATE: Account Created" >> $SCRIPT_LOG_FILE
}

recreate_account &
conjurctl server > /opt/conjur-server/log/conjur-server.log

