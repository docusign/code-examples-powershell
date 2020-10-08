$apiUri = "https://demo.docusign.net/restapi"

# List the envelope's documents
# This script uses the envelope_id stored in ../envelope_id.
# The envelope_id file is created by example eg002SigningViaEmail.ps1 or
# can be manually created.

# ***DS.snippet.0.start
# Step 1. Obtain your Oauth access token
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
  Write-Output "PROBLEM: An envelope id is needed. Fix: execute step 2 - Signing_Via_Email"
  exit 1
}

Write-Output "Sending the EnvelopeDocuments::list request to DocuSign..."
Write-Output "Results:"

# Step 2. List envelope documents
Invoke-RestMethod `
  -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/documents" `
  -Method 'GET' `
  -Headers @{
  'Authorization' = "Bearer $accessToken";
  'Content-Type'  = "application/json";
}
# ***DS.snippet.0.end

Write-Output "Done."
