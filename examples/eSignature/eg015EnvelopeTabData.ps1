$apiUri = "https://demo.docusign.net/restapi"

# Retrieve Envelope Tab Data

# Step 1. Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Check that we have an envelope ID
if (Test-Path .\config\ENVELOPE_ID) {
  $envelopeId = Get-Content .\config\ENVELOPE_ID
}
else {
  Write-Output "An envelope id is needed. Fix: execute step 2 - Signing_Via_Email"
  exit 1
}

# Step 2. Create your authorization headers
#ds-snippet-start:eSign15Step2
$headers = @{
  'Authorization' = "Bearer $accessToken";
  'Accept'        = "application/json";
  'Content-Type'  = "application/json";
}
#ds-snippet-end:eSign15Step2

# Step 3. a) Make a GET call to the form_data endpoint to retrieve your envelope tab values
#         b) Display the JSON response
#ds-snippet-start:eSign15Step3
$result = $(Invoke-WebRequest `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/form_data" `
    -Method 'GET' `
    -Headers $headers)
#ds-snippet-end:eSign15Step3

if ( $result.StatusCode -gt 201) {
  Write-Output "Retrieving envelope form data has failed."
  Write-Output $result
  exit 0
}

Write-Output "Response:"
Write-Output $result
