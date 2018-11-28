#!/bin/bash

function usage () {
        echo
        echo "Usage: ./DownloadFile.sh -f \"File Name\" -s \"Syncpoint Name\" -p \"Folder Path\""
        echo
        echo
        echo "-f - File Name. If the name has spaces it must be inside double quotes."
        echo "-p - Folder Path. If the name has spaces it must be inside double quotes."
        echo "-s - Syncpoint Name. If the name has spaces it must be inside double quotes."
        echo
        echo "Examples:"
        echo "./DownloadFile.sh -f \"File Name\" -s \"Syncpoint Name\""
        echo "./DownloadFile.sh -f \"File Name\" -s \"Syncpoint Name\" -p \"Folder Path\""
        exit 2


}

Path=
while getopts "f:p:s:h" opt
do
        case ${opt} in
                f) File=$OPTARG ;;
                p) Path=$OPTARG ;;
                s) Syncpoint=$OPTARG ;;
                h) usage ;;
        esac
done

SyncpointID=$(./FileFolderMetadata.sh -o get-syncpoints | jq '.[] | "\(.Id) \(.Name)"' | tr -d '"' | \
grep -iw "$Syncpoint" | awk '{print $1}')
FileID=$(./FileFolderMetadata.sh -o get-files -s "$Syncpoint" -f "$Path" | jq ".[] | select(.Filename==\"$File\")" | \
grep LatestVersionId | cut -d ':' -f2 | tr -d '", ')

if [[ -z ${File} ]] ; then echo "Please enter file!" && usage ; fi
if [[ -z ${Syncpoint} ]] ; then echo "Please enter file!" && usage ; fi

if [[ -z ${Path} ]] ; then echo "Please enter folder path!" && usage ; fi

Credentials=$(./Authentication.sh)
appkey=$(echo "${Credentials}" | grep 'App Key' | cut -d : -f2 | tr -d ' ')
accesstoken=$(echo "${Credentials}" | grep 'Access Token' | cut -d : -f2 | tr -d ' ')

if [ -z ${appkey} ] || [ -z ${accesstoken} ] ; then
  echo "Authentication failed!" && exit 1;
fi

# Please note that this script is strictly using Syncplicity public US cloud (https://data.syncplicity.com).
# In case you would like to support different endpoints, the endpoint must be discovered.
curl -o ${File} -sS -X GET -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
"https://data.syncplicity.com/v2/files?syncpoint_id={SyncpointID}&file_version_id={FileID}"
