# Returns the status of whether or not jurisdictions are disabled

$apiUri = "https://notary-d.docusign.net/restapi"

# Step 1. Obtain your Oauth access token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountID = Get-Content .\config\API_ACCOUNT_ID

# Step 2. Make a GET request to the jurisdictions endpoint

$response = New-TemporaryFile

Write-Output "Sending the jurisdiction status request to DocuSign..."
Write-Output ""
Write-Output "Results:"

Invoke-RestMethod `
	-UseBasicParsing `
    -Uri "${apiUri}/v1.0/accounts/${accountID}/jurisdictions" `
    -Method 'GET' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
  } `
  	-OutFile $response

Write-Output "Response: $(Get-Content -Raw $response)"
Write-Output ""
Write-Output "Done..."
