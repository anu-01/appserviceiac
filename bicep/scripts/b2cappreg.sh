#!/bin/bash

# Usage: ./b2cappreg.sh b2c-tenant-id customer-name sp-app-id sp-secret customer-app-name b2c-name
az login --service-principal -u $3 -p $4 --allow-no-subscriptions --tenant $1
echo 'Login Completed'
AppName="$2appreg"    
echo AppName = $AppName

MainUri="https://$6.b2clogin.com/$6.onmicrosoft.com/oauth2/authresp"
SignUpInUri="https://$5.azurewebsites.net/B2C_1_signupsignin1"
SignInOidcUri="https://$5.azurewebsites.net/signin-oidc"

clientid=$(az ad app create --display-name $AppName --enable-access-token-issuance true --enable-id-token-issuance true --web-redirect-uris $MainUri $SignUpInUri $SignInOidcUri --query appId --output tsv)
echo clientid = $clientid
objectid=$(az ad app show --id $clientid --query id --output tsv)
echo objectid = $objectid    
az ad app list --display-name $AppName #(Gives details of newly created app)
echo Listed app    
###Create an AAD service principal
spid=$(az ad sp create --id $clientid --query objectId --output tsv)
az ad app permission admin-consent --id $spid
### Add permissions
az ad app update --id $objectid --required-resource-accesses '[{"resourceAppId": "00000003-0000-0000-c000-000000000000","resourceAccess": [{ "id": "7427e0e9-2fba-42fe-b0c0-848c9e6a8182","type": "Scope"},{"id": "37f7f235-527c-4136-accd-4a02d197296e","type": "Scope"}]}]'
### Return the outputs to Bicep
echo '{ "clientid": "'$clientid'", "objectId": "'$objectid'", "appSecret": "'$password'"}' > $AZ_SCRIPTS_OUTPUT_PATH        