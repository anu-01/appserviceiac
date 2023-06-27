#!/bin/bash

# Usage: ./b2cappreg.sh b2c-tenant-id customer-name sp-app-id sp-secret
az login --service-principal -u $3 -p $4 --allow-no-subscriptions --tenant $1
echo 'Login Completed'
AppName="$2appreg"    
echo AppName = $AppName

MainUri="https://rusmithb2c.b2clogin.com/rusmithb2c.onmicrosoft.com/oauth2/authresp"
SignUpInUri="https://$2.azurewebsites.net/B2C_1_signupsignin1"
SignInOidcUri="https://$2.azurewebsites.net/signin-oidc"

#
#az ad app create --display-name $AppName --web-redirect-uris MainUri SignUpInUri SignInOidcUri

clientid=$(az ad app create --display-name $AppName --web-redirect-uris $MainUri $SignUpInUri $SignInOidcUri --query appId --output tsv)
echo clientid = $clientid
objectid=$(az ad app show --id $clientid --query id --output tsv)
echo objectid = $objectid    
az ad app list --display-name $AppName #(Gives details of newly created app)
echo Listed app    
#password=$(az ad app credential reset --id $clientid --append --query password --output tsv)
#echo password = $password
echo '{ "clientid": "'$clientid'", "objectId": "'$objectid'", "appSecret": "'$password'"}' > $AZ_SCRIPTS_OUTPUT_PATH