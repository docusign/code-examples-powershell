# Invite a notary to join your pool

$apiUri = "https://notary-d.docusign.net/restapi"


# Step 1. Obtain your Oauth access token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt
$accountID = Get-Content .\config\API_ACCOUNT_ID
$response = New-TemporaryFile

# Construct your API headers

# Step 2 Start
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
# Step 2 End

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Check that we have an organization id in the settings.json config file
if (!$variables.ORGANIZATION_ID) {
    Write-Output "Organization ID is needed. Please add the ORGANIZATION_ID variable to the settings.json"
    exit -1
}

$organizationId = $variables.ORGANIZATION_ID


Write-Output ""
Write-Output "Retrieving your notary pool:"
Write-Output ""

# Step 3 Start
Invoke-RestMethod `
    -UseBasicParsing `
    -Uri "${apiUri}/v1.0/organizations/${organizationId}/pools/" `
    -Headers $headers `
    -Method 'GET' `
    -OutFile $response

Write-Output "Response: $(Get-Content -Raw $response)"
$POOL_ID = $(Get-Content $response | ConvertFrom-Json).pools[0].poolId
# Step 3 End

# Step 4 Start
write-Output ""
$NOTARY_NAME = Read-Host "Enter a name for the notary"
$NOTARY_EMAIL = Read-Host "Enter an email address for the notary"

$body = @"
{
  "email" : "${NOTARY_EMAIL}",
  "name" : "${NOTARY_NAME}",
}
"@
# Step 4 End

# Step 5 Start
write-Output ""
write-Output "Inviting ${NOTARY_NAME} to your organization's notary pool"
write-Output ""
write-Output "Pool id is ${POOL_ID}"
write-Output ""
Invoke-RestMethod `
    -Uri "${apiUri}/v1.0/organizations/${organizationId}/pools/${POOL_ID}/invites" `
    -Headers $headers `
    -Method 'POST' `
    -Body $body `
    -Outfile $response

Write-Output "Response: $(Get-Content -Raw $response)"
# Step 5 End

# cleanup
Remove-Item $response
Write-Output ""
Write-Output "Done..."