#!/bin/bash

function usage () {
        echo
        echo "Usage: ./UploadFile.sh -f \"File Name\" -s \"Syncpoint Name\" -p \"Path\""
        echo
        echo
        echo "-f - File Name. Local file to be uploaded. Either the file name or full local path to the file. \
        If the name has spaces it must be inside double quotes."
        echo "-p - Path. Path to file in Syncplicity. Should not include Syncpoint (top level folder) name or filename. \
        If the name has spaces it must be inside double quotes."
        echo "-s - Syncpoint Name. If the name has spaces it must be inside double quotes."
        echo
        echo "Examples:"
        echo "./UploadFile.sh -f \"File Name\" -s \"Syncpoint Name\""
        exit 2


}

while getopts "f:p:s:h" opt
do
        case ${opt} in
                f) File=$OPTARG ;;
                p) Path=$OPTARG ;;
                s) Syncpoint=$OPTARG ;;
                h) usage ;;
        esac
done

if [[ -z ${File} ]] ; then echo "Please enter file!" && usage ; fi
if [[ -z ${Syncpoint} ]] ; then echo "Please enter file!" && usage ; fi
StorageID=$(./FileFolderMetadata.sh -o get-syncpoints | jq '.[] | "\(.Id) \(.Name)"' | tr -d '"' | \
grep -iw "${Syncpoint}" | awk '{print $1}')
Filename=$(echo ${File} | awk -F / '{print $NF}')
url_path=$(echo "${Path}\\${Filename}" | sed -e 's/\\/%5C/g' | sed -e 's/ /%20/g')

Credentials=$(./Authentication.sh)
appkey=$(echo "${Credentials}" | grep 'App Key' | cut -d : -f2 | tr -d ' ')
accesstoken=$(echo "${Credentials}" | grep 'Access Token' | cut -d : -f2 | tr -d ' ')

if [ -z ${appkey} ] || [ -z ${accesstoken} ] ; then
  echo "Authentication failed!" && exit 1;
fi

Hash=$(sha256sum ${File} | cut -d ' ' -f1)

# Please note that this script is strictly using Syncplicity public US cloud (https://data.syncplicity.com).
# In case you would like to support different endpoints, the endpoint must be discovered.
curl -Ss -X POST -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" -H "User-Agent: API-User-Agent" \
-H "Content-Range: 0-*/*" -F "sessionKey=Bearer ${accesstoken}"  -F "filename=${File}" -F "fileData=@${File}" \
-F "transfer-encoding=binary" -F "type=application/octet-stream" -F "sha256=${Hash}" -F "virtualFolderId=${StorageID}" \
-F "fileDone=" "https://data.syncplicity.com/v2/mime/files?filepath=${url_path}"
