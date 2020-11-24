# https://developers.docusign.com/docs/esign-rest-api/how-to/unpause-workflow/

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$oAuthAccessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Create temp files
$requestData = New-TemporaryFile
$response = New-TemporaryFile

# Check that we have an envelope id
if (Test-Path .\config\ENVELOPE_ID) {
    $envelopeID = Get-Content .\config\ENVELOPE_ID
}
else {
    Write-Output "PROBLEM: An envelope id is needed. Fix: execute step 32 - Pause_Signature_Workflow"
    exit 1
}

# Step 2. Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

# Step 3.Construct the JSON body for your envelope
@{
    workflow =
    @{
        workflowStatus = "in_progress";
    };
} | ConvertTo-Json -Depth 32 > $requestData

# Step 4. Call the eSignature API
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/${APIaccountId}/envelopes/${envelopeId}?resend_envelope=true"
Invoke-RestMethod `
    -Uri $uri `
    -Method 'PUT' `
    -Headers @{
    'Authorization' = "Bearer $oAuthAccessToken";
    'Accept'        = "application/json";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response

Write-Output ""
Write-Output "Request: $(Get-Content -Raw $requestData)"
Write-Output $(Get-Content -Raw $response)

# Delete temp files
Remove-Item $requestData
Remove-Item $response