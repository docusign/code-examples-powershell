# Send a signing request via email using a DocuSign template

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

$CC_EMAIL = [System.Environment]::ExpandEnvironmentVariables($variables.CC_EMAIL)
$CC_NAME = [System.Environment]::ExpandEnvironmentVariables($variables.CC_NAME)
$SIGNER_EMAIL = [System.Environment]::ExpandEnvironmentVariables($variables.SIGNER_EMAIL)
$SIGNER_NAME = [System.Environment]::ExpandEnvironmentVariables($variables.SIGNER_NAME)

# Configuration
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
    Write-Output "`nPROBLEM: A template id is needed. Fix: execute step 8 - Create_Template`n"
    exit 0
}

$apiUri = "https://demo.docusign.net/restapi"

# ***DS.snippet.0.start
# Step 1. Create the envelope request.
# temp files:
$response = New-TemporaryFile
$requestData = New-TemporaryFile

Write-Output ""
Write-Output "Sending the envelope request to DocuSign..."

@{
    templateId    = "$(Get-Content .\config\TEMPLATE_ID)";
    templateRoles = @(
        @{
            email    = $SIGNER_EMAIL;
            name     = $SIGNER_NAME;
            roleName = "signer";
        };
        @{
            email    = $CC_EMAIL;
            name     = $CC_NAME;
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

Write-Output ""
Write-Output "Response:"
Get-Content $response

# cleanup
Remove-Item $response
Remove-Item $requestData

Write-Output ""
Write-Output "Done."
Write-Output ""