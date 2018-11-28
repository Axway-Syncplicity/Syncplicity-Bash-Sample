#!/bin/bash

function usage () {
        echo
        echo "Usage: ./UserAPIs.sh -o [Option] -u Username -g \"Group Name\" -s \"Syncpoint Name\" -f \"File Name\" \
-l \"Folder Name\" -w [0/1] -p Password -e [0/1] -t Time(numeric value) -d [1/2/3/4] -m [1/2/3/4] "
        echo
        echo "Options:"
        echo "-o - options are:"
        echo
        echo "get-all-links - Show all links."
        echo "create-link - Create new link."
        echo "delete-link - Delete user."
        echo "get-link - Show link details."
        echo "edit-link - Edit single link."
        echo
        echo "-u - Username (email)."
        echo "-g - Group Name. If the name has spaces it must be inside double quotes."
        echo "-s - Syncpoint Name. If the name has spaces it must be inside double quotes."
        echo "-f - File name. If the name has spaces it must be inside double quotes."
        echo "-l - Path. Path to file in Syncplicity. Should not include Syncpoint (top level folder) name or filename. \
        If the name has spaces it must be inside double quotes."
        echo "-w - With password. Enable password protection. 1 is disabled, 2 is enabled. Default is 1."
        echo "-p - Password for the link."
        echo "-e - Expiration enabled. 0 to disable expiration, 1 to enable. Default is 1."
        echo "-t - Time period for expiration."
        echo "-d - Shared link policy. 1 for disabled, 2 for internal domain only, 3 for allow all and 4 for \
intended only(user or group). Default value is 3."
        echo "-m - Outlook sharing policy. 1 for disabled, 2 for internal domain only, 3 for allow all and 4 for \
intended only(user or group). Default value is 3."
        echo
        echo "Examples:"
        echo "./LinksAPIs.sh -o get-all-links"
        echo "./LinksAPIs.sh -o create-link -f \"File Name\" -l \"Folder Name\" -s \"Syncpoint Name \""
        echo "./LinksAPIs.sh -o edit-link -u Username/-g Group -f \"File Name\" -l \"Folder Name\" \
-s \"Syncpoint Name \""
        echo
        exit 2


}

Disable=3
Mail=3
WithPass=1
Expiration=1
Time=60
USER=

while getopts "o:u:g:s:f:l:p:e:t:d:m:h" opt
do
        case ${opt} in
                o) OPTION=$OPTARG ;;
                u) USER=$OPTARG ;;
                g) Group=$OPTARG ;;
                s) Syncpoint=$OPTARG ;;
                f) File=$OPTARG ;;
                l) Path=$OPTARG ;;
                p) Password=$OPTARG ;;
                e) Expiration=$OPTARG ;;
                t) Time=$OPTARG ;;
                w) WithPass=$OPTARG ;;
                d) Disable=$OPTARG ;;
                m) Mail=$OPTARG ;;
                h) usage ;;
        esac
done

Credentials=$(./Authentication.sh)
appkey=$(echo "${Credentials}" | grep 'App Key' | cut -d : -f2 | tr -d ' ')
accesstoken=$(echo "${Credentials}" | grep 'Access Token' | cut -d : -f2 | tr -d ' ')

if [ -z ${appkey} ] || [ -z ${accesstoken} ] ; then
  echo "Authentication failed!" && exit 1;
fi

if [[ ! -z ${Path} ]] ; then
  if [ "${Path: -1}" != "\\" ] ; then
    Path="${Path}\\"
  fi
  Path=$(echo ${Path} | sed -e 's/\\/\\\\/g')
fi

VerifySyncpoint ()
{
  if [[ -z ${Syncpoint} ]] ; then
    echo "Missing Syncpoint!" && usage
  fi
}

VerifyUserOrGroup ()
{
  if [[ ! -z ${Group} ]] && [[ ! -z ${USER} ]] ; then
    echo "Cannot use both user and group, enter only one of the two!" && usage
  elif [[ -z ${Group} ]] && [[ -z ${USER} ]] ; then
    echo "No user or group entered!" && usage
  fi
}

GetAllLinks ()
{
  curl -sS -X GET -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " "https://api.syncplicity.com/syncpoint/links.svc/" | jq .
}

GetSyncpointID ()
{
  VerifySyncpoint
  ./FileFolderMetadata.sh -o get-syncpoints -s ${Syncpoint} | jq '.[] | "\(.Id) \(.Name)"' | tr -d '"' \
  | grep -iw "$Syncpoint" | awk '{print $1}'
}

GetGroupID ()
{
  VerifyUserOrGroup
  ./GroupAPIs.sh -o get-all-groups | jq ".[] | select(.Name==\"$Group\")" | jq .Id | tr -d '" '
}

UserOrGroup ()
{
  if [ ${Disable} = 4 ] ; then
    if [[ ! -z ${USER} ]] && [[ -z ${Group} ]] ; then
      echo -n '"Users": [ {"EmailAddress": "'${USER}'"} ], '
    elif [[ ! -z ${Group} ]] && [[ -z ${USER} ]] ; then
      echo -n '"Groups": [ {"Id": "'$(GetGroupID)'"} ], '
    fi
  fi
}

GetUserID ()
{
  VerifyUserOrGroup
  ./UserAPIs.sh -o show-user -u ${USER} | jq .Id | tr -d '" '
}

JQUserOrGroup ()
{
  if [[ -z ${USER} ]] && [[ ! -z ${Group} ]] ; then
    echo -n '(.Groups[].Name=="'${Group}'")'
  elif [[ -z ${Group} ]] && [[ ! -z ${USER} ]] ; then
    echo -n '(.Users[].Id=="'$(GetUserID)'")'
  fi
}

GetToken ()
{
  VerifyUserOrGroup
  GetAllLinks | jq ".[] | select((.File.Filename==\"$File\") and $(JQUserOrGroup)).Token" | tr -d '" '
}

CreateLink ()
{
  if [ ${Disable} = 4 ] ; then VerifyUserOrGroup ; fi
  request=$(curl -sS -X POST -H "Accept: application/json" -H "AppKey: ${appkey}" \
  -H "Authorization: Bearer ${accesstoken}" -H "As-User: " -H "Content-Type: application/json" \
  -d "[ {\"SyncPointId\": \"$(GetSyncpointID)\", \"VirtualPath\": \"$Path\", \"ShareLinkPolicy\": $Disable, \
  \"PasswordProtectPolicy\": $WithPass, \"Password\": \"$Password\", $(UserOrGroup)\"Message\": \"\", \
  \"OutlookShareLinkPolicy\": \"3\", \"LinkExpirationPolicy\": $Expiration, \"LinkExpireInDays\": \"$Time\"} ]" \
  "https://api.syncplicity.com/syncpoint/links.svc/")
  echo ${request} | jq .
}


DeleteLink ()
{
  curl -X DELETE -H "Accept: application/json" -H "AppKey: ${appkey}" \
  -H "Authorization: Bearer ${accesstoken}" -H "As-User: " \
  "https://api.syncplicity.com/syncpoint/link.svc/$(GetToken)"
}

GetLink ()
{
  curl -sS -X GET -H "As-User: " -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Accept: application/json" "https://api.syncplicity.com/syncpoint/link.svc/$(GetToken)"
}

EditLink ()
{
  curl -sS -X PUT -H "As-User: " -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Accept: " -H "Content-Type: application/json" \
  -d "{\"SyncpointID\": \"$(GetSyncpointID)\", \"VirtualPath\": \"$Path\", \"ShareLinkPolicy\": $Disable, \
  \"PasswordProtectPolicy\": $WithPass, \"Password\": \"$Password\", $(UserOrGroup)\"Message\": \"\", \
  \"OutlookShareLinkPolicy\": \"3\", \"LinkExpirationPolicy\": $Expiration, \"LinkExpireInDays\": \"$Time\"}" \
  "https://api.syncplicity.com/syncpoint/link.svc/$(GetToken)" | jq .
}

if [[ ${OPTION} = 'get-all-links' ]] ; then
  GetAllLinks
elif [[ ${OPTION} = 'create-link' ]] ; then
  CreateLink
elif [[ ${OPTION} = 'delete-link' ]] ; then
  DeleteLink
elif [[ ${OPTION} = 'get-link' ]] ; then
  GetLink
elif [[ ${OPTION} = 'edit-link' ]] ; then
  EditLink
else
  echo "Wrong Option!" && usage
fi
