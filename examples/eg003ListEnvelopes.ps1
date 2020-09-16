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

$basePath="https://demo.docusign.net/restapi"

Write-Output "`nSending the list envelope status request to DocuSign..."
Write-Output "`nResults:"

# Get date in the ISO 8601 format
$fromDate = ((Get-Date).adddays(-10d)).ToString("yyyy-MM-ddThh:mm:ssK")

$headers = @{
  Authorization="Bearer $accessToken"
}

try {
  $(Invoke-RestMethod -Method Get `
    -Headers $headers `
    -Uri $basePath/v2.1/accounts/$accountID/envelopes `
    -ContentType application/json `
    -Body @{ "from_date" = $fromDate }).envelopes
  Write-Output "`nDone...`n"
}
catch {
  Write-Error "Something went wrong " $_.Exception.Response.StatusCode
}