$apiUri = "https://demo.docusign.net/restapi"

# List envelopes and their status
# List changes for the last 10 days


# Step 1. Obtain your Oauth access token
$accessToken = Get-Content .\config\ds_access_token.txt

# Step 2. List envelope status
#ds-snippet-start:eSign3Step2
# Obtain your accountId from demo.docusign.net -- the account id is shown in
# the drop down on the upper right corner of the screen by your picture or
# the default picture.
$accountID = Get-Content .\config\API_ACCOUNT_ID

Write-Output "Sending the list envelope status request to Docusign..."
Write-Output "Results:"

# Get date in the ISO 8601 format
$fromDate = ((Get-Date).AddDays(-10d)).ToString("yyyy-MM-ddTHH:mm:ssK")


$(Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'GET' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
  } `
    -Body @{ "from_date" = ${fromDate} }).envelopes
#ds-snippet-end:eSign3Step2
Write-Output "Done."
