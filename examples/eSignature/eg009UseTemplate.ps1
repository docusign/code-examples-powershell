# Eg009 Use template

$apiUri = "https://demo.docusign.net/restapi"

# Send a signing request via email using a DocuSign template

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Step 1. Obtain your OAuth access token

$accessToken = Get-Content .\config\ds_access_token.txt

# Obtain your accountId from demo.docusign.net -- the account id is shown in
# the drop down on the upper right corner of the screen by your picture or
# the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Check that we have a template id
if (-not (Test-Path .\config\TEMPLATE_ID)) {
    Write-Output "A template id is needed. Fix: execute step 8 - Create_Template"
    exit 0
}

# Step 2. Create the envelope definition from a template
# temp files:
$response = New-TemporaryFile
$requestData = New-TemporaryFile

Write-Output "Sending the envelope request to DocuSign..."

#ds-snippet-start:eSign9Step2
@{
    templateId    = "$(Get-Content .\config\TEMPLATE_ID)";
    templateRoles = @(
        @{
            email    = $variables.SIGNER_EMAIL;
            name     = $variables.SIGNER_NAME;
            roleName = "signer";
        };
        @{
            email    = $variables.CC_EMAIL;
            name     = $variables.CC_NAME;
            roleName = "cc";
        };
    );
    status        = "sent";
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:eSign9Step2

# Step 3. Create and send the envelope
#ds-snippet-start:eSign9Step3
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path  `
    -OutFile $response
#ds-snippet-end:eSign9Step3


Write-Output "Response:"
Get-Content $response

# cleanup
Remove-Item $response
Remove-Item $requestData

# ***DS.snippet.0.end

Write-Output "Done."
