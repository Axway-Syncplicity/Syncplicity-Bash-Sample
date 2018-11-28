#!/bin/bash

function usage () {
        echo
        echo "Usage: ./UserAPIs.sh -o [Option] -u Username -f \"First Name\" -l \"Last Name\" -p Password -e Email \
-t Type -r Role -d [0/1] -a [0/1] "
        echo
        echo "Options:"
        echo "-o - options are:"
        echo
        echo "get-users - Show all users."
        echo "create-user - Create new user. Must input username and type."
        echo "delete-user - Delete user."
        echo "get-user - Show user details."
        echo "edit-user - Edit single user. Enable/Disable user. Activate/Deactivate user. Change email (with -e), \
first or last name, password or role."
        echo "edit-users - Edit multiple users. Can't enable/disable or activate/deactivate. Can change account type."
        echo "company-details - Show company details."
        echo
        echo "-u - Username (email)."
        echo "-f - First Name. If the name has spaces it must be inside double quotes."
        echo "-l - Last Name. If the name has spaces it must be inside double quotes."
        echo "-p - Password for account."
        echo "-e - Email for account."
        echo "-t - Type of account. Account types are:"
        echo
        echo "                3 - PaidBusiness: A user who is subscribed to Syncplicity as part of a business account."
        echo "                7 - LimitedBusiness: users who have been added to a company account but not yet \
provided their personal details."
        echo "               14 - TrialBusiness: A user who is subscribed to Syncplicity as part of a business \
trial account and hasn't previous subscription."
        echo "               16 - PendingBusiness: A user who is suggested to be added to a company account, \
but not yet approved by a company administrator."
        echo
        echo "-r - Role of account. Possible users roles:"
        echo "                1 - AccountOwner (Global administrator and account owner)."
        echo "                2 - Administrator (Global administrator)."
        echo "                3 - Support (Support tools)."
        echo "                4 - ReportViewer (Report viewer)."
        echo "                5 - SupportAdmin (Support administrator)."
        echo "                6 - EDiscoveryAdmin (E-Discovery administrator)."
        echo
        echo "-d - Disabled flag. 1 for disabled, 0 for enabled. Default value is 0."
        echo "-a - Active flag. 1 for active 0 for inactive. Default value is 1."
        echo
        echo "Examples:"
        echo "./UserAPIs.sh -o show-users"
        echo "./UserAPIs.sh -o create-user -u Username -f \"First Name\" -l \"Last Name\" -p Password -t Type -r Role"
        echo "./UserAPIs.sh -o edit-user -u Username -f \"First Name\" -l \"Last Name\" -p Password -r Role \
-e Email -d [0/1] -a [0/1]"
        exit 2


}

Disable=0
Active=1

while getopts "o:u:f:l:p:e:t:r:d:a:h" opt
do
        case ${opt} in
                o) OPTION=$OPTARG ;;
                u) USER=$OPTARG ;;
                f) FirstName=$OPTARG ;;
                l) LastName=$OPTARG ;;
                p) Password=$OPTARG ;;
                e) Email=$OPTARG ;;
                t) Type=$OPTARG ;;
                r) Role=$OPTARG ;;
                d) Disable=$OPTARG ;;
                a) Active=$OPTARG ;;
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


GetAllUsers ()
{
  curl -sS -X GET -H "Accept: application/json" -H "Content-Type: application/json" -H "AppKey: ${appkey}" \
  -H "Authorization: Bearer ${accesstoken}" \
  https://api.syncplicity.com/provisioning/company_users.svc/company/${companyID}/users | jq .
}

CreateUser ()
{
  VerifyUser
  VerifyType
  curl -sS -X POST -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Accept: application/json"  -H "Content-Type: application/json" \
  -d "[ {\"EmailAddress\": \"$USER\", \"FirstName\": \"$FirstName\", \"LastName\": \"$LastName\", \
  \"AccountType\": {$Type}, \"Roles\": [$Role], \"Password\": \"$Password\"} ]" \
  "https://api.syncplicity.com/provisioning/users.svc/?modifier=no_email" | jq .
}

Deleteuser ()
{
  VerifyUser
  curl -X DELETE -H "AppKey:  ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Accept: application/json" "https://api.syncplicity.com/provisioning/user.svc/$USER"
}

GetUser ()
{
  VerifyUser
  curl -sS -X GET -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Accept: application/json" "https://api.syncplicity.com/provisioning/user.svc/$USER" | jq .
}

EditUser ()
{
  VerifyUser
  curl -sS -X PUT -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Accept: application/json" -H "Content-Type: application/json" \
  -d "{\"EmailAddress\": \"$Email\", \"FirstName\": \"$FirstName\", \"LastName\": \"$LastName\", \"Roles\": [$Role], \
  \"Password\": \"$Password\", \"Disabled\":$Disable, \"Active\":$Active}" \
  "https://api.syncplicity.com/provisioning/user.svc/$USER?modifier=no_email" | jq .
}

EditUsers ()
{
  # This method can be used to edit multiple users. In it's current form, it only updates one user, but one can see the
  # syntax and adjust it accordingly (add more users in the body using the same format).
  VerifyUser
  VerifyType
  curl -sS -X PUT -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Content-Type: application/json" \
  -d "[ {\"EmailAddress\": \"$USER\", \"FirstName\": \"$FirstName\", \"LastName\": \"$LastName\", \"Roles\": [$Role], \
  \"Password\": \"$Password\", \"AccountType\": {$Type} } ]" "https://api.syncplicity.com/provisioning/users.svc/"
}

GetCompany ()
{
  curl -sS -X GET -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Accept: application/json" "https://api.syncplicity.com/provisioning/company.svc/${companyID}" \
  | jq .
}

GetDevices ()
{
  curl -sS -X GET -H "AppKey: ${appkey}" -H "Authorization: Bearer ${accesstoken}" \
  -H "Accept: application/json" "https://api.syncplicity.com/provisioning/machines.svc/" | jq .
}

VerifyUser ()
{
  if [[ -z ${USER} ]] ; then echo "Missing Username! This option is mandatory!" && usage ; fi
}

VerifyType ()
{
  if [[ -z ${Type} ]] ; then echo "Missing Type! This option is mandatory!" && usage ; fi
}

if [[ ${OPTION} = 'get-users' ]] ; then
  GetAllUsers
elif [[ ${OPTION} = 'create-user' ]] ; then
  CreateUser
elif [[ ${OPTION} = 'delete-user' ]] ; then
  DeleteUser
elif [[ ${OPTION} = 'get-user' ]] ; then
  GetUser
elif [[ ${OPTION} = 'edit-user' ]] ; then
  EditUser
elif [[ ${OPTION} = 'edit-users' ]] ; then
  EditUsers
elif [[ ${OPTION} = 'company-details' ]] ; then
  GetCompany
elif [[ ${OPTION} = 'get-devices' ]] ; then
  GetDevices
else
  echo "Wrong Option!" && usage
fi
