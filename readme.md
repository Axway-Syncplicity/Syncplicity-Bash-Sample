# Syncplicity-Bash-Sample

## Description

This sample application demonstrates various API calls including the initial OAuth2 authentication call. This is a CLI application that does not support SSO-based authentication, so would be the basis of an application typically used by an administrator, not a regular Syncplicity user.

Each script includes a usage description and only implements API calls required for its purpose. However, some scripts have dependencies on other scripts, so please make sure to preserve their relative location on disk.

These scripts are just samples of API calls in Bash. To implement your specific use case it is better to create your own script, as it can be done more efficiently (e.g. in these samples authentication occurs in every class, and with a dedicated script it can be implemented to happen only once).

## System Requirements

* Supported OSes: CentOS Linux, should also work on other Linux versions
* jq - <https://stedolan.github.io/jq/>

### Installation

If you don't have the required packages installed, please install them.

You can download jq from <https://stedolan.github.io/jq/> and install as per the instructions there.

Alternatively, you can install it using your package manager if it is available there.
To install jq using a package manager in RHEL/CentOS, install EPEL repository and then jq:

    yum install epel-release
    yum install jq

In case you use a different distribution, please install them using your package manager.

Make sure all .sh files are executable.
You can configure that by issuing the following command:

    chmod +x *.sh

## Usage

These sample scripts demonstrate usage of Syncplicity APIs. This is what you need to know or do before you begin to use Syncplicity APIs:

* Make sure you have an Enterprise Edition account you can use to login to the Developer Portal at <https://developer.syncplicity.com>.
* Log into Syncplicity Developer Portal using your Syncplicity login credentials.
  Only Syncplicity Enterprise Edition users are allowed to login to the Developer Portal.
  Based on the configuration done by your Syncplicity administrator,
  Syncplicity Developer Portal will present one of the following options for login:
  * Basic Authentication using Syncplicity username and password.
  * Enterprise Single Sign-on using the web SSO service used by your organization. We support ADFS, OneLogin, Ping and Okta.
* Once you have successfully logged in for the first time,
  you must create an Enterprise Edition sandbox account in the Developer Portal.
  This account can be used to safely test your application using all Syncplicity features
  without affecting your company production data.
  * Log into Syncplicity Developer Portal. Click 'My Profile' and then 'Create sandbox'.
    Refer to the documentation for guidance: <https://developer.syncplicity.com/documentation/overview>.
  * You can log into <https://my.syncplicity.com> using the sandbox account.
    Note that the sandbox account email has "-apidev" suffix.
    So, assuming you regular account email is user@domain.com,
    use user-apidev@domain.com email address to log in to your sandbox account.
* Setup your developer sandbox account:
  * Log into the sandbox account at <https://my.syncplicity.com> to make sure its correctly provisioned and that you can access it.
  * Go to the 'Account' menu.
  * Click "Create" under "Application Token" section.
    The token is used to authenticate an application before making API calls.
    Learn more [here](https://syncplicity.zendesk.com/hc/en-us/articles/115002028926-Getting-Started-with-Syncplicity-APIs).
* Review API documentation by visiting documentation section on the <https://developer.syncplicity.com>.
* Register you application in the Developer Portal to obtain the "App Key" and "App Secret".

## Running

1. Clone the sample project.
2. Define new application on <https://developer.syncplicity.com>. The application key and application secret values are found in the application page.
  The Syncplicity application token is found on the "My Account" page of the Syncplicity administration page.
  Use the "Application Token" field on that page to generate a token.
3. Update key values in `Credentials.txt`:
    * Update the `App Key`
    * Update the `App Secret`
    * Update the `Application Token`
4. Run the application.

* Please note that every script (except for Authentication.sh which shouldn't be called on it's own) contains its own usage function that can be called with -h flag.

## Samples

There are two sample files in the sample_files folder.

SampleGroup file can be used for group APIs for group creation.
In order to use it, you will need to insert a group name in the designated place and insert the owner email.

SamplePolicy file can be used for policy creation.
It is all set to create a new policy set called TestPolicy with default configuration.

Both files contain only mandatory fields.
In order to make a more advanced use of that, please visit the documentation for these APIs at [Syncplicity Developer Portal](<https://developer.syncplicity.com>) to see the additional parameters.

## Limitations

This sample supports US ROL only.
This sample supports US Public Cloud storage only.
Upload/download to on-premise storages requires Storage Endpoint discovery via corresponding API.

## Team

![alt text][Axwaylogo] Axway Syncplicity Team

[Axwaylogo]: https://github.com/Axway-syncplicity/Assets/raw/master/AxwayLogoSmall.png "Axway logo"

## License

Apache License 2.0
