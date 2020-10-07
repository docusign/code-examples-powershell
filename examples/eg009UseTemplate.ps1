$apiUri = "https://demo.docusign.net/restapi"

# Send a signing request via email using a DocuSign template

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json


# 1. Search for and update '{USER_EMAIL}' and '{USER_FULLNAME}'.
#    They occur and re-occur multiple times below.
# 2. Obtain an OAuth access token from
#    https://developers.docusign.com/oauth-token-generator
$accessToken = Get-Content .\config\ds_access_token.txt

# 3. Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Check that we have a template id
if (-not (Test-Path .\config\TEMPLATE_ID)) {
    Write-Output "PROBLEM: A template id is needed. Fix: execute step 8 - Create_Template"
    exit 0
}

# ***DS.snippet.0.start
# Step 1. Create the envelope request.
# temp files:
$response = New-TemporaryFile
$requestData = New-TemporaryFile

Write-Output "Sending the envelope request to DocuSign..."

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

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path  `
    -OutFile $response
# ***DS.snippet.0.end

Write-Output "Response:"
Get-Content $response

# cleanup
Remove-Item $response
Remove-Item $requestData

Write-Output "Done."
