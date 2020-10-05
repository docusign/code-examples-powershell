$apiUri = "https://demo.docusign.net/restapi"

# Embedded signing ceremony

# Get required variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Configuration
# 1. Obtain an OAuth access token from
#    https://developers.docusign.com/oauth-token-generator
$accessToken = Get-Content .\config\ds_access_token.txt

# 2. Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountID = Get-Content .\config\API_ACCOUNT_ID

# ***DS.snippet.0.start
# Step 1. Create the envelope.
#         The signer recipient includes a clientUserId setting
#
#  document 1 (pdf) has tag /sn1/
#  The envelope has two recipients.
#  recipient 1 - signer
#  recipient 2 - cc
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile

# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $doc1Base64

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
        carbonCopies = @(
            @{
                email        = $variables.CC_EMAIL;
                name         = $variables.CC_NAME;
                recipientId  = "2";
                routingOrder = "2";
            };
        );
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

# Step 2. Create a recipient view (a signing ceremony view)
#         that the signer will directly open in their browser to sign.
#
# The returnUrl is normally your own web app. DocuSign will redirect
# the signer to returnUrl when the signing ceremony completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from DocuSign

Write-Output "Requesting the url for the signing ceremony..."

$json = [ordered]@{
    'returnUrl'            = 'http://httpbin.org/get';
    'authenticationMethod' = 'none';
    'email'                = $variables.SIGNER_EMAIL;
    'userName'             = $variables.SIGNER_NAME;
    'clientUserId'         = 1000
} | ConvertTo-Json -Compress

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
$signingCeremonyUrl = $(Get-Content $response | ConvertFrom-Json).url

# ***DS.snippet.0.end
Write-Output "The signing ceremony URL is $signingCeremonyUrl"
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser..."

Start-Process $signingCeremonyUrl

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64

Write-Output "Done."
