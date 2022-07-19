$apiUri = "https://demo.docusign.net/restapi"
$configPath = ".\config\settings.json"
$tokenPath = ".\config\ds_access_token.txt"
$accountIdPath = ".\config\API_ACCOUNT_ID"

# Check the folder structure to switch paths for Quick ACG
if ((Test-Path $configPath) -eq $false) {
    $configPath = "..\config\settings.json"
}
if ((Test-Path $tokenPath) -eq $false) {
    $tokenPath = "..\config\ds_access_token.txt"
}
if ((Test-Path $accountIdPath) -eq $false) {
    $accountIdPath = "..\config\API_ACCOUNT_ID"
}

# Use embedded signing

# Get required variables from .\config\settings.json file
$variables = Get-Content $configPath -Raw | ConvertFrom-Json

# 1. Obtain your OAuth token
$accessToken = Get-Content $tokenPath

# Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountID = Get-Content $accountIdPath

# Step 2. Create the envelope definition.
# The signer recipient includes a clientUserId setting
#
#  document 1 (PDF) has tag /sn1/
#  recipient 1 - signer
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile

$docPath = ".\demo_documents\World_Wide_Corp_lorem.pdf"

# Check the folder structure to switch paths for Quick ACG
if ((Test-Path $docPath) -eq $false) {
    $docPath = "..\demo_documents\World_Wide_Corp_lorem.pdf"
}

# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path $docPath))) > $doc1Base64

Write-Output "Sending the envelope request to DocuSign..."

# Concatenate the different parts of the request
@{
    emailSubject = "Please sign this document set";
    documents    = @(
        @{
            documentBase64 = "$(Get-Content $doc1Base64)";
            name           = "Lorem Ipsum";
            fileExtension  = "pdf";
            documentId     = "1";
        };
    );
    recipients   = @{
        signers      = @(
            @{
                email        = $variables.SIGNER_EMAIL;
                name         = $variables.SIGNER_NAME;
                recipientId  = "1";
                routingOrder = "1";
                clientUserId = "1000";
                tabs         = @{
                    signHereTabs = @(
                        @{
                            anchorString  = "/sn1/";
                            anchorUnits   = "pixels";
                            anchorXOffset = "20";
                            anchorYOffset = "10";
                        };
                    );
                };
            };
        );
    };
    status       = "sent";
} | ConvertTo-Json -Depth 32 > $requestData

# Step 3. Call DocuSign to create the envelope
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response

Write-Output "Response: $(Get-Content -Raw $response)"

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
Write-Output "EnvelopeId: $envelopeId"

# Step 4. Create a recipient view definition
# The signer will directly open this link from the browser to sign.
#
# The returnUrl is normally your own web app. DocuSign will redirect
# the signer to returnUrl when the signing completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from DocuSign

Write-Output "Requesting the url for the embedded signing..."

$json = [ordered]@{
    'returnUrl'            = 'http://httpbin.org/get';
    'authenticationMethod' = 'none';
    'email'                = $variables.SIGNER_EMAIL;
    'userName'             = $variables.SIGNER_NAME;
    'clientUserId'         = 1000
} | ConvertTo-Json -Compress


# Step 5. Create the recipient view and begin the DocuSign signing
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/views/recipient" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -Body $json `
    -OutFile $response

Write-Output "Response: $(Get-Content -Raw $response)"
$signingUrl = $(Get-Content $response | ConvertFrom-Json).url

# ***DS.snippet.0.end
Write-Output "The embedded signing URL is $signingUrl"
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser..."

Start-Process $signingUrl

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64

Write-Output "Done."
