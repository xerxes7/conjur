#!/bin/bash

echo -n " Please enter user name: "
read username
echo -n " Please enter user password: "
read -s password
default_orgUrl="https://dev-842018.oktapreview.com"

read -e -p "`echo -e '\nPlease enter OKTA url [https://dev-842018.oktapreview.com]: '`" orgUrl
echo "Doing primary authentication..."
orgUrl="${orgUrl:-${default_orgUrl}}"
raw=`curl -s -H "Content-Type: application/json" -d "{\"username\": \"${username}\", \"password\": \"${password}\"}" ${orgUrl}/api/v1/authn`
echo ${raw}
status=`echo ${raw} | jq -r '.status'`
echo "status=${status}"
stateToken=`echo $raw | jq -r '.stateToken'`
pushFactorId=`echo $raw | jq -r '.["_embedded"].factors[0].id'`

echo "Congratulations! You got a stateToken: ${stateToken} That's used in a multi-step authentication flow, like MFA."

echo "Sending Okta Verify push notification..."
status="MFA_CHALLENGE"
tries=0
while [[ ${status} == "MFA_CHALLENGE" && ${tries} -lt 10 ]]
    do
      verifyAndPoll=`curl -s -H "Content-Type: application/json" -d "{\"stateToken\": \"${stateToken}\"}" ${orgUrl}/api/v1/authn/factors/${pushFactorId}/verify`
      #echo "verifyAndPoll=${verifyAndPoll}"
      status=`echo ${verifyAndPoll} | jq -r '.status'`
      tries=$((tries+1))
      echo "Polling for push approve..."
      sleep 6
    done

sessionToken=`echo ${verifyAndPoll} | jq -r '.sessionToken'`


client_id="0oagd87pc7rUCknhR0h7"
redirect_uri="http://locallhost.com/"

echo "Fetching ID Token using sessionToken ${sessionToken}"

url=$(printf "%s/oauth2/v1/authorize?sessionToken=%s&client_id=%s&scope=openid+email&response_type=id_token&response_mode=fragment&nonce=%s&redirect_uri=%s&state=%s" \
      $orgUrl \
      $sessionToken \
      $client_id \
      "staticNonce" \
      $redirect_uri \
      "staticState")
echo ${url}
raw=`curl -s -v  ${url} 2>&1`

echo "ID Token of the user"
id_token=$(echo "${raw}" | egrep -o '.*ocation: .*id_token=[[:alnum:]_\.\-]*' | cut -d \= -f 2)
echo ${id_token}
