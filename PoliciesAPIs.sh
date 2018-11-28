#!/bin/bash

function usage () {
        echo
        echo "Usage: ./PoliciesAPIs.sh -o [Option] -p \"Policy Name\" -f \"File Name\" -t Type"
        echo
        echo "Options:"
        echo "-o - options are:"
        echo
        echo "get-policies - Show all policies."
        echo "get-policies-by-type - Show policies by their type."
        echo "get-policy - Show single policy by policy name."
        echo "delete-policies - Delete policies."
        echo "delete-policy - Delete single policy."
        echo "create-policy - Create new policy. Use file to set policy settings. Use -f flag to insert file name."
        echo "edit-policy - Edit policy by name. Use file to set policy settings. Use -f flag to insert file name."
        echo
        echo "-f - File Name. If the name has spaces it must be inside double quotes. \
This is used for policies settings (edit or create) and contains the desired policy settings. You can find a sample \
file under sample_files called SamplePolicy"
        echo "-p - Policy name. If the name has spaces it must be inside double quotes."
        echo "-t - Policy type. Types are: PolicySet, StorageSet, HomeDirectorySet"
        echo
        echo "Examples:"
        echo "./PoliciesAPIs.sh -o get-policies"
        echo "./PoliciesAPIs.sh -o create-policy -f \"File Name\""
        echo "./PoliciesAPIs.sh -o edit-policy -p \"Policy Name\" -f \"File Name\""
        echo
        exit 2


}


while getopts "o:f:p:t:h" opt
do
        case ${opt} in
                o) OPTION=$OPTARG ;;
                f) File=$OPTARG ;;
                p) PolicyName=$OPTARG ;;
                t) Type=$OPTARG ;;
                h) usage ;;
        esac
done

Credentials=$(./Authentication.sh)
appkey=$(echo "${Credentials}" | grep 'App Key' | cut -d : -f2 | tr -d ' ')
accesstoken=$(echo "${Credentials}" | grep 'Access Token' | cut -d : -f2 | tr -d ' ')
companyID=$(echo "${Credentials}" | grep 'Company ID' | cut -d : -f2 | tr -d ' ')

if [ -z ${appkey} ] || [ -z ${accesstoken} ] ||  [ -z ${companyID} ]; then
  echo "Authentication failed!" && exit 1;
fi


GetAllPolicies ()
{
  curl -sS -X GET -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" -H "Accept: application/json" \
  "https://api.syncplicity.com/provisioning/policysets.svc/" | jq .
}

GetPolicyID ()
{
  if [[ -z ${PolicyName} ]] ; then echo "Please enter policy name!" && usage ; fi
  GetAllPolicies | jq '.[] |"\(.Id) \(.Name)"' | grep -iw "$PolicyName" | awk '{print $1}' | tr -d '" '
}

PoliciesDelete ()
{
  curl -X DELETE -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" -H "Accept: application/json" \
  -H "Content-Type: application/json" -d "[ {\"Id\": \"$(GetPolicyID)\"} ]" \
  "https://api.syncplicity.com/provisioning/policysets.svc/"
}

PolicyByType ()
{
  if [[ -z ${Type} ]] ; then echo "Please enter type!" && usage ; fi
  curl -sS -X GET -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" -H "Accept: application/json" \
  "https://api.syncplicity.com/provisioning/policysets.svc/$companyID/$Type" | jq .
}

PolicyDelete ()
{
  curl -sS -X DELETE -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" -H "Accept: application/json" \
  -H "Content-Type: application/json" -d "{\"Id\": \"$(GetPolicyID)\"}" \
  "https://api.syncplicity.com/provisioning/policyset.svc/"
}

GetPolicy ()
{
  curl -sS -X GET -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" -H "Accept: application/json" \
  "https://api.syncplicity.com/provisioning/policyset.svc/$(GetPolicyID)" | jq .
}

CreatePolicy ()
{
  VerifyFile
  curl -sS -X POST -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" -H "Accept: application/json" \
  -H "Content-Type: application/json" -d @${File} "https://api.syncplicity.com/provisioning/policysets.svc/" \
  | jq.
}

EditPolicy ()
{
  VerifyFile
  sed -i "2i\ \ \ \ \"Id\": \"$(GetPolicyID)\"," ${File}
  curl -v -sS -X PUT -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" -H "Accept: application/json" \
  -H "Content-Type: application/json" -d @${File} "https://api.syncplicity.com/provisioning/policyset.svc/" \
  | jq .
}

VerifyFile ()
{
  if [[ ! -f ${File} ]] ; then echo "Please enter valid file!" && usage ; fi
}

if [[ ${OPTION} = 'get-policies' ]] ; then
  GetAllPolicies
elif [[ ${OPTION} = 'delete-policies' ]] ; then
  PoliciesDelete
elif [[ ${OPTION} = 'get-policies-by-type' ]] ; then
  PolicyByType
elif [[ ${OPTION} = 'delete-policy' ]] ; then
  PolicyDelete
elif [[ ${OPTION} = 'get-policy' ]] ; then
  GetPolicy
elif [[ ${OPTION} = 'create-policy' ]] ; then
  CreatePolicy
elif [[ ${OPTION} = 'edit-policy' ]] ; then
  EditPolicy
else
  echo "Wrong Option!" && usage
fi
