# Retreive Envelope Tab Data

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

$apiUri = "https://demo.docusign.net/restapi"

# Check that we have an envelope ID
if (Test-Path .\config\ENVELOPE_ID) {
  $envelopeId = Get-Content .\config\ENVELOPE_ID
}
else {
  Write-Output "`nPROBLEM: An envelope id is needed. Fix: execute step 2 - Signing_Via_Email`n"
  exit 1
}

#Step 2: Create your authorization headers
$headers = @{
  'Authorization' = "Bearer $accessToken";
  'Accept'        = "application/json";
  'Content-Type'  = "application/json";
}

# Step 3: a) Make a GET call to the form_data endpoint to retrieve your envelope tab values
#         b) Display the JSON response
$result = $(Invoke-WebRequest `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/form_data" `
    -Method 'GET' `
    -Headers $headers)

if ( $result.StatusCode -gt 201) {
  Write-Output ""
  Write-Output "Retrieving envelope form data has failed."
  Write-Output $result
  exit 0
}

Write-Output ""
Write-Output "Response:"
Write-Output $result
Write-Output ""
