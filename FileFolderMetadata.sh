#!/bin/bash

function usage () {
        echo
        echo "Usage: ./FileFolderMetadata.sh -o [Option] -f [\"Folder Path\"] -s [\"Syncpoint Name\"] \
-n [\"New Folder Name\"] -e [\"Existing Filename\"] -b [\"Storage Endpoint Description\"] \
-v [\"File version\"] -p [0/1/3]"
        echo
        echo "Options:"
        echo "-o - options are:"
        echo
        echo "get-syncpoints - Get all syncpoints."
        echo "get-folders - Get all folders from syncpoint."
        echo "get-sub-folders - Get all sub-folders from folder."
        echo "get-files - Get files from folder. Requires syncpoint and folder."
        echo "delete-folder - Delete folder. Requires syncpoint and folder."
        echo "create-folder - Create folder. Requires syncpoint, folder and new folder name."
        echo "get-default-storage - Get default storage vault."
        echo "get-storage-endpoint - Get a certain storage endpoint. Requires storage endpoint description (-b)."
        echo "get-storage-endpoints - Get all storage endpoints."
        echo "get-file-versions - Get all versions of a file. Requires existing filename (-e), \
syncpoint and folder name."
        echo "delete-file-version - Delete a certain version of a file."
        echo "get-sp-participants - Show participants in syncpoint."
        echo "remove-sp-participant - Remove single user from syncpoint. Only using email address, no group option."
        echo "add-sp-participant - Add user to syncpoint. Permission is optional. Default is read-only."
        echo "edit-sp-participant - Edit existing participant. Change permission level."
        echo "remove-sp-participants - Remove users or groups from syncpoint."
        echo
        echo "-f - Folder path. If folder name has spaces it must be inside double quotes."
        echo "-s - Syncpoint name. If syncpoint name has spaces it must be inside double quotes."
        echo "-n - New folder name. If folder name has spaces it must be inside double quotes. \
Only used with create-folder option."
        echo "-e - Existing Filename."
        echo "-b - Storage Endpoint Description. Only used for get-storage-endpoint."
        echo "-v - File version. 0 is first version. Only used for delete-file-version."
        echo "-p - Permission. Used for syncpoint sharing participants. 0 means no share, \
1 means read/write and 3 is read-only."
        echo "-r - Remove status for file. 3 is to remove, 5 is to confirm removed (remove option to restore file). \
Default is 3."
        echo
        echo "Examples:"
        echo "./FileFolderMetadata.sh -o get-syncpoints"
        echo "./FileFolderMetadata.sh -o get-files -s \"Syncpoint Name\" -f \"Folder Path\""
        echo
        exit 2


}

Permission=3
RemoveStatus=3

while getopts "o:u:f:s:n:e:b:v:p:r:h" opt
do
        case ${opt} in
                o) OPTION=$OPTARG ;;
                u) USER=$OPTARG ;;
                f) FolderPath=$OPTARG ;;
                s) Syncpoint=$OPTARG ;;
                n) NewFolderName=$OPTARG ;;
                e) ExistingFilename=$OPTARG ;;
                b) StorageEndpoint=$OPTARG ;;
                v) FileVersion=$OPTARG ;;
                p) Permission=$OPTARG ;;
                r) RemoveStatus=$OPTARG ;;
                h) usage ;;
        esac
done

Credentials=$(./Authentication.sh)
appkey=$(echo "${Credentials}" | grep 'App Key' | cut -d : -f2 | tr -d ' ')
accesstoken=$(echo "${Credentials}" | grep 'Access Token' | cut -d : -f2 | tr -d ' ')

if [ -z ${appkey} ] || [ -z ${accesstoken} ] ; then
  echo "Authentication failed!" && exit 1;
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ ! -z ${FolderPath} ]] ; then
  if [ "${FolderPath: -1}" != "\\" ] ; then
    FolderPath="${FolderPath}\\"
  fi
  FolderPath=$(echo ${FolderPath} | sed -e 's/\\/\\\\/g')
fi

GetAllSyncpoints ()
{
  curl -sS -X GET -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " "https://api.syncplicity.com/syncpoint/syncpoints.svc/?includeType=1,2,3,4,5,6,7,8" \
  | jq .
}

GetSyncpointID ()
{
  if [[ -z ${Syncpoint} ]] ; then echo "Syncpoint name is missing" && usage ; fi
  GetAllSyncpoints | jq '.[] | "\(.Id) \(.Name)"' | tr -d '"' | grep -iw "$Syncpoint" | awk '{print $1}'
}

GetRootFolderID ()
{
  if [[ -z ${Syncpoint} ]] ; then echo "Syncpoint name is missing" && usage ; fi
  GetAllSyncpoints | jq '.[] | "\(.RootFolderId) \(.Name)"' | tr -d '"' | grep -iw "$Syncpoint" | awk '{print $1}'
}

GetFoldersFromSyncpoint ()
{
  curl -sS -X GET -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  "https://api.syncplicity.com/sync/folders.svc/$(GetSyncpointID)/folders" | jq .
}

GetFolderID ()
{
  if [[ -z ${FolderPath} ]] ; then echo "Folder name is missing" && usage ; fi
  GetFoldersFromSyncpoint | jq '.[] |"\(.FolderId) \(.VirtualPath)"' | tr -d '",' | grep -Fiw "$FolderPath" | awk '{print $1}'
}

GetFilesFromFolder ()
{
  curl -sS -X GET -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " \
  "https://api.syncplicity.com/sync/folder_files.svc/$(GetSyncpointID)/folder/$(GetFolderID)/files" \
  | jq .
}

GetFileID ()
{
  GetFilesFromFolder | jq ".[] | select(.Filename==\"$ExistingFilename\")" | grep LatestVersionId \
  | cut -d ':' -f2 | tr -d '", '
}

GetSubFoldersFromFolder ()
{
  curl -sS -X GET -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " \
  "https://api.syncplicity.com/sync/folder_folders.svc/$(GetSyncpointID)/folder/$FolderID/folders" | jq .
}

DeleteFolder ()
{
  if [[ ${FolderPath} = "/" ]] ; then echo "Cannot delete since this is a syncpoint" && exit 1 ; fi
  curl -X DELETE -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " "https://api.syncplicity.com/sync/folder.svc/$(GetSyncpointID)/folder/$(GetFolderID)"
}

CreateFolder ()
{
  curl -X POST -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " -H "Content-Type: application/json" \
  -d "[ {\"Name\": \"$NewFolderName\",\"Status\": 1} ]" \
  "https://api.syncplicity.com/sync/folder_folders.svc/$(GetSyncpointID)/folder/$FolderID/folders" | jq .
}

CreateFolderSP ()
{
  SYNCPOINT_ID=$(GetSyncpointID)
  VirtualPath="$(echo -n '\\')$NewFolderName$(echo -n '\\')"
  curl -sS -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "AppKey: ${appkey}" \
  -H "Authorization: Bearer ${accesstoken}" -d "[ {\"SyncpointId\": \"$SYNCPOINT_ID\", \"Name\": \"$NewFolderName\", \
  \"Status\": 1, \"VirtualPath\": \"$VirtualPath\"} ]" \
  "https://api.syncplicity.com/sync/folders.svc/$SYNCPOINT_ID/folders" | jq .
}

GetDefaultStorage ()
{
  curl -sS -X GET -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " "https://api.syncplicity.com/storage/storageendpoint.svc/" | jq .

}

GetFileVersions ()
{
  curl -sS -X GET -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " "https://api.syncplicity.com/sync/versions.svc/$(GetSyncpointID)/file/$(GetFileID)/versions" \
  | jq .
}

GetStorageEndpoints ()
{
  curl -sS -X GET -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  "https://api.syncplicity.com/storage/storageendpoints.svc/" | jq .
}

GetStorageEndpoint ()
{
  curl -sS -X GET -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " \
  "https://api.syncplicity.com/storage/storageendpoint.svc/$(GetStorageEndpoints | jq ".[] | \
  select(.Description==\"$StorageEndpoint\")" | grep -iw "id" | cut -d ':' -f2 | tr -d '", ')" | jq .
}

DeleteFileVersion ()
{
  FileVersionID=$(GetFileVersions | jq .[${FileVersion}].Id)
  curl -X DELETE -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " \
  "https://api.syncplicity.com/sync/version.svc/$(GetSyncpointID)/file/$(GetFilesFromFolder | jq ".[] | \
  select(.Filename==\"$ExistingFilename\")" | grep -iw "FileId" | cut -d ':' -f2 | tr -d '", ')/version/$FileVersionID"
}

CreateSyncpoint ()
{
  curl -X POST -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " -H "Content-Type: application/json" \
  -d "[ {\"Type\": 6, \"Name\": \"$NewFolderName\", \"Mapped\": false, \"DownloadEnabled\": false, \
  \"UploadEnabled\": false, \"StorageEndpointID\": \"$(GetDefaultStorage | jq .Id | tr -d '" ')\"} ]" \
  "https://api.syncplicity.com/syncpoint/syncpoints.svc/" | jq .
}

DeleteSyncpoint ()
{
  curl -X DELETE -H "As-User: " -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Accept: application/json" -H "Content-Type: " \
  "https://api.syncplicity.com/syncpoint/syncpoint.svc/$(GetSyncpointID)"
}

EditSyncpoint ()
{
  curl -X PUT -H "As-User: " -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Accept: application/json" -H "Content-Type: application/json" -d "{\"Type\": 8}" \
  "https://api.syncplicity.com/syncpoint/syncpoint.svc/$(GetSyncpointID)"

}

GetSyncpointParticipants ()
{
  curl -sS -X GET -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " "https://api.syncplicity.com/syncpoint/syncpoint_participants.svc/$(GetSyncpointID)/participants" \
  | jq .
}

DeleteSyncpointParticipant ()
{
  curl -X DELETE -H "Accept: " -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  "https://api.syncplicity.com/syncpoint/syncpoint_participant.svc/$(GetSyncpointID)/participant/$USER"
}

AddSyncpointParticipant ()
{
  curl -sS -X POST -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " -H "Content-Type: application/json" \
  -d "[ {\"User\": {\"EmailAddress\": \"$USER\"}, \"Permission\": \"$Permission\", \"SharingInviteNote\": \"\"} ]" \
  "https://api.syncplicity.com/syncpoint/syncpoint_participants.svc/$(GetSyncpointID)/participants" \
  | jq .
}

EditSyncpointParticipant ()
{
  curl -sS -X PUT -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Content-Type: application/json" -d "{\"User\": {\"EmailAddress\": \"$USER\"}, \"Permission\": \"$Permission\", \
  \"SharingInviteNote\": \"\"}" \
  "https://api.syncplicity.com/syncpoint/syncpoint_participant.svc/$(GetSyncpointID)/participant/$USER" \
  | jq .
}

DeleteSyncpointParticipants ()
{
  curl -X DELETE -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " -H "Content-Type: application/json" \
  -d "[ {\"User\": {\"EmailAddress\": \"$USER\"}} ]" \
  "https://api.syncplicity.com/syncpoint/syncpoint_participants.svc/$(GetSyncpointID)/participants"
}

DeleteFileFromSyncpoint ()
{
  SYNCPOINT_ID=$(GetSyncpointID)
  #VirtualPath="$(echo -n '\\')$FolderName$(echo -n '\\')"
  VirtualPath="$(echo -n '\')" #$ExistingFilename$(echo -n '\\')"
  curl -X DELETE -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Content-Type: application/json" -d "[ {\"SyncpointId\": \"$SYNCPOINT_ID\", \"Filename\": \"$ExistingFilename\", \
  \"Status\": $RemoveStatus, \"VirtualPath\": \"\\\"} ]" \
  "https://api.syncplicity.com/sync/files.svc/$SYNCPOINT_ID/files"
}

DeleteFile ()
{
  curl -X DELETE -H "Accept: application/json" -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "As-User: " "https://api.syncplicity.com/sync/file.svc/$(GetSyncpointID)/file/$(GetFileID)"
}

if [[ ${FolderPath} = "/" ]] ; then FolderID=$(GetRootFolderID) ; else FolderID=$(GetFolderID) ; fi

if [[ ${OPTION} = 'get-syncpoints' ]]; then
  GetAllSyncpoints
elif [[ ${OPTION} = 'get-folders' ]]; then
  GetFoldersFromSyncpoint
elif [[ ${OPTION} = 'get-sub-folders' ]]; then
  GetSubFoldersFromFolder
elif [[ ${OPTION} = 'get-files' ]]; then
  GetFilesFromFolder
elif [[ ${OPTION} = 'delete-folder' ]]; then
  DeleteFolder
elif [[ ${OPTION} = 'create-folder' ]]; then
  CreateFolder
elif [[ ${OPTION} = 'create-folder-sp' ]]; then
  CreateFolderSP
elif [[ ${OPTION} = 'get-default-storage' ]]; then
  GetDefaultStorage
elif [[ ${OPTION} = 'get-file-versions' ]]; then
  GetFileVersions
elif [[ ${OPTION} = 'get-storage-endpoints' ]]; then
  GetStorageEndpoints
elif [[ ${OPTION} = 'get-storage-endpoint' ]]; then
  GetStorageEndpoint
elif [[ ${OPTION} = 'delete-file-version' ]]; then
  DeleteFileVersion
elif [[ ${OPTION} = 'create-syncpoint' ]]; then
  CreateSyncpoint
elif [[ ${OPTION} = 'delete-syncpoint' ]]; then
  DeleteSyncpoint
elif [[ ${OPTION} = 'get-sp-participants' ]]; then
  GetSyncpointParticipants
elif [[ ${OPTION} = 'remove-sp-participant' ]]; then
  DeleteSyncpointParticipant
elif [[ ${OPTION} = 'add-sp-participant' ]]; then
  AddSyncpointParticipant
elif [[ ${OPTION} = 'edit-sp-participant' ]]; then
  EditSyncpointParticipant
elif [[ ${OPTION} = 'remove-sp-participants' ]]; then
  DeleteSyncpointParticipants
elif [[ ${OPTION} = 'delete-file-from-sp' ]]; then
  DeleteFileFromSyncpoint
elif [[ ${OPTION} = 'delete-file' ]]; then
  DeleteFile
elif [[ ${OPTION} = 'edit-syncpoint' ]]; then
  EditSyncpoint
else
  echo -e "\n${RED}No such option!${NC} " && usage
fi
