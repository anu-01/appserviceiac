#!/bin/bash

# Usage: ./b2cappreg.sh b2c-tenant-id customer-name sp-app-id sp-secret
az login --service-principal -u $3 -p $4 --allow-no-subscriptions --tenant $1

AppName="$2appreg"    
MainUri="https://rusmithb2c.b2clogin.com/rusmithb2c.onmicrosoft.com/oauth2/authresp"
SignUpInUri="https://$2.azurewebsites.net/B2C_1_signupsignin1"
SignInOidcUri="https://$2.azurewebsites.net/signin-oidc"


az ad app create --display-name $AppName --web-redirect-uris MainUri SignUpInUri SignInOidcUri
    
az ad app list --display-name $AppName #(Gives details of newly created app)
    
#az ad app update --id APP_ID_FROM_ABOVE_CMD --reply-urls  [https://jwt.ms](https://jwt.ms/)  (update any values in app)