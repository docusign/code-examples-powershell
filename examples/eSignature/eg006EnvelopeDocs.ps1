$apiUri = "https://demo.docusign.net/restapi"

# List the envelope's documents
# This script uses the envelope_id stored in ../envelope_id.
# The envelope_id file is created by example eg002SigningViaEmail.ps1 or
# can be manually created.

# ***DS.snippet.0.start
# Obtain your Oauth access token
$accessToken = Get-Content .\config\ds_access_token.txt

# Obtain your accountId from demo.docusign.net -- the account id is shown in
# the drop down on the upper right corner of the screen by your picture or
# the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Check that we have an envelope id
if (Test-Path .\config\ENVELOPE_ID) {
  $envelopeID = Get-Content .\config\ENVELOPE_ID
}
else {
  Write-Output "An envelope id is needed. Fix: execute step 2 - Signing_Via_Email"
  exit 1
}

#ds-snippet-start:eSign6Step2
$headers = @{
  'Authorization' = "Bearer $accessToken";
  'Content-Type'  = "application/json";
}
#ds-snippet-end:eSign6Step2

Write-Output "Sending the EnvelopeDocuments::list request to DocuSign..."
Write-Output "Results:"

# List envelope documents
#ds-snippet-start:eSign6Step3
Invoke-RestMethod `
  -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/documents" `
  -Method 'GET' `
  -Headers $headers | ConvertTo-Json
#ds-snippet-end:eSign6Step3

Write-Output "Done."
