# List envelopes and their status
# List changes for the last 10 days

# Configuration
# 1. Obtain an OAuth access token from
#    https://developers.docusign.com/oauth-token-generator
$accessToken = Get-Content .\config\ds_access_token.txt

# 2. Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountID = Get-Content .\config\API_ACCOUNT_ID

$apiUri = "https://demo.docusign.net/restapi"

Write-Output "`nSending the list envelope status request to DocuSign..."
Write-Output "`nResults:"

# Get date in the ISO 8601 format
$fromDate = ((Get-Date).adddays(-10d)).ToString("yyyy-MM-ddThh:mm:ssK")

$(Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'Get' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
  } `
    -Body @{ "from_date" = ${fromDate} }).envelopes

Write-Output "`nDone...`n"