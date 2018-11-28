#!/usr/bin/env bash

cd $(dirname $0)

Authentication_File='Credentials.txt'

appkey=$(grep 'App Key' ${Authentication_File} | cut -d : -f2 | tr -d ' ')
appsecret=$(grep 'App Secret' ${Authentication_File} | cut -d : -f2 | tr -d ' ')
usersyncplicityapptoken=$(grep 'Application Token' ${Authentication_File} | cut -d : -f2 | tr -d ' ')
basicAuthToken=$(echo -n "${appkey}:${appsecret}" | base64)

oauthresult=$(curl -sS -X POST https://api.syncplicity.com/oauth/token -H 'Authorization: Basic '${basicAuthToken} \
-H "Sync-App-Token: ${usersyncplicityapptoken}" -d 'grant_type=client_credentials')

accesstoken=$(echo ${oauthresult} | sed -e 's/[{}"]/''/g' | awk -v RS=',' -F: '/^access_token/ {print $2}')
companyID=$(echo ${oauthresult} | sed -e 's/[{}"]/''/g' | awk -v RS=',' -F: '/^user_company_id/ {print $2}')

echo -e "App Key: ${appkey}\nAccess Token: ${accesstoken}\nCompany ID:${companyID}"
