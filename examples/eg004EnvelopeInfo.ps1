# Get the envelope's details
#
# This script uses the envelope_id stored in ../envelope_id.
# The envelope_id file is created by example eg002SigningViaEmail.sh or
# can be manually created.

# Configuration
# 1. Obtain an OAuth access token from
#    https://developers.docusign.com/oauth-token-generator
# $accessToken = Get-Content .\config\ds_access_token.txt
$accessToken = Get-Content ([System.IO.Path]::Combine($PSScriptRoot, "..\config\ds_access_token.txt"))

# 2. Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
# $accountId = Get-Content .\config\API_ACCOUNT_ID
$accountId = Get-Content ([System.IO.Path]::Combine($PSScriptRoot, "..\config\API_ACCOUNT_ID"))

$basePath = "https://demo.docusign.net/restapi"

# Check that we have an envelope id
if (Test-Path .\config\ENVELOPE_ID) {
  # $envelopeID = Get-Content .\config\ENVELOPE_ID
  $envelopeID = Get-Content ([System.IO.Path]::Combine($PSScriptRoot, "..\config\ENVELOPE_ID"))
}
else {
  Write-Output "`nPROBLEM: An envelope id is needed. Fix: execute step 2 - Signing_Via_Email`n"
  exit 1
}

Write-Output ""
Write-Output "Sending the Envelopes::get request to DocuSign..."
Write-Output ""
Write-Output "Results:"

# ***DS.snippet.0.start
$headers = @{
  'Authorization' = "Bearer $accessToken"
  'Content-Type'  = 'application/json'
}

$parameters = @{
  Uri    = $basePath + "/v2.1/accounts/" + $accountId + "/envelopes/" + $envelopeId
  Method = 'GET'
}

try {
  Invoke-RestMethod -Headers $headers @parameters
}
catch {
  Write-Error  $_
}
# ***DS.snippet.0.end

Write-Output ""
Write-Output "Done."
Write-Output ""
