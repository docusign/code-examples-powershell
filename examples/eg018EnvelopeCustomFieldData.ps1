$apiUri = "https://demo.docusign.net/restapi"

# Get the envelope's custom field data
# This script uses the envelope ID stored in ../envelope_id.
# The envelope_id file is created by example eg016SetTabValues.sh or
# can be manually created.

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

#Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# temp files:
$response = New-TemporaryFile

# Check that we have an template ID
if (Test-Path .\config\ENVELOPE_ID) {
  $envelopeId = Get-Content .\config\ENVELOPE_ID
}
else {
  Write-Output "PROBLEM: An envelope id is needed. Fix: execute step 16 - Set_Tab_Values"
  exit 1
}

Write-Output "Sending the EnvelopeCustomFields::list request to DocuSign..."

#Step 2: a) Create your authorization headers
#        b) Send a GET request to the Envelopes endpoint
Invoke-RestMethod `
  -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/custom_fields" `
  -Method 'GET' `
  -Headers @{
  'Authorization' = "Bearer $accessToken";
  'Content-Type'  = "application/json";
} `
  -OutFile $response

Write-Output "Results:"

Get-Content $response

# cleanup
Remove-Item $response

Write-Output "Done."
