$apiUri = "https://demo.docusign.net/restapi"

# Get the envelope's custom field data
# This script uses the envelope ID stored in ../envelope_id.
# The envelope_id file is created by example eg016SetTabValues.ps1 or
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
  Write-Output "An envelope id is needed. Fix: execute step 16 - Set_Tab_Values"
  exit 1
}

Write-Output "Sending the EnvelopeCustomFields::list request to DocuSign..."

# Step 2. Create your authorization headers
#ds-snippet-start:eSign18Step2
$headers = @{
  'Authorization' = "Bearer $accessToken";
  'Content-Type'  = "application/json";
}
#ds-snippet-end:eSign18Step2

# Step 3. Call the eSignature REST API
#ds-snippet-start:eSign18Step3
Invoke-RestMethod `
  -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/custom_fields" `
  -Method 'GET' `
  -Headers $headers `
  -OutFile $response
#ds-snippet-end:eSign18Step3

Write-Output "Results:"

Get-Content $response

# cleanup
Remove-Item $response

Write-Output "Done."
