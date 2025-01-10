$apiUri = "https://demo.docusign.net/restapi"
$configPath = ".\config\settings.json"
$tokenPath = ".\config\ds_access_token.txt"
$accountIdPath = ".\config\API_ACCOUNT_ID"

# Get required variables from .\config\settings.json file
$variables = Get-Content $configPath -Raw | ConvertFrom-Json

# 1. Obtain your OAuth token
$accessToken = Get-Content $tokenPath

# Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountID = Get-Content $accountIdPath

# Step 2. Create the envelope definition.

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

Write-Output "Sending the envelope request to Docusign..."
Write-Output ""

# Concatenate the different parts of the request
#ds-snippet-start:eSign44Step2
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
#ds-snippet-end:eSign44Step2

# Step 3. Call Docusign to create the envelope
#ds-snippet-start:eSign44Step3
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response
#ds-snippet-end:eSign44Step3

Write-Output "Response: $(Get-Content -Raw $response)"
Write-Output ""

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
Write-Output "EnvelopeId: $envelopeId"
Write-Output ""

# Step 4. Create a recipient view definition
# The signer will directly open this link from the browser to sign.
#
# The returnUrl is normally your own web app. Docusign will redirect
# the signer to returnUrl when the signing completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from Docusign

#ds-snippet-start:eSign44Step4
Write-Output "Requesting the url for the embedded signing..."
Write-Output ""

$json = @{
    returnUrl = "http://httpbin.org/get"
    authenticationMethod = "none"
    email = $variables.SIGNER_EMAIL
    userName = $variables.SIGNER_NAME
    clientUserId = 1000
    frameAncestors = @("http://localhost:8080", "https://apps-d.docusign.com")
    messageOrigins = @("https://apps-d.docusign.com")
}

$jsonString = $json | ConvertTo-Json
#ds-snippet-end:eSign44Step4

# Step 5. Create the recipient view and begin the Docusign signing
#ds-snippet-start:eSign44Step5
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/views/recipient" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -Body $jsonString `
    -OutFile $response

Write-Output "Response: $(Get-Content -Raw $response)"

$signingUrl = $(Get-Content $response | ConvertFrom-Json).url
#ds-snippet-end:eSign44Step5

Start-Process -NoNewWindow -FilePath "powershell" -ArgumentList "-File .\utils\startServerForFocusedView.ps1 -signingURL $signingUrl"

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64

Write-Output ""
Write-Output "Done."