$apiUri = "https://demo.docusign.net/restapi"

# Use embedded sending:
# 1. create a draft envelope with three documents
# 2. Open the sending view of the DocuSign web tool

# Configuration
# 1.  Get required variables from .\config\settings.json:
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$CC_EMAIL = $variables.CC_EMAIL
$CC_NAME = $variables.CC_NAME
$SIGNER_EMAIL = $variables.SIGNER_EMAIL
$SIGNER_NAME = $variables.SIGNER_NAME

# 2. Search for and update '{USER_EMAIL}' and '{USER_FULLNAME}'.
#    They occur and re-occur multiple times below.

$accessToken = Get-Content .\config\ds_access_token.txt

# Obtain your accountId from demo.docusign.net -- the account id is shown in
# the drop down on the upper right corner of the screen by your picture or
# the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

# The sending editor can be opened in either of two views:
Enum ViewType {
    TaggingView = 1;
    RecipientsAndDocuments = 2;
}

$startingView = $null;
do {
    Write-Output 'Select the initial sending view: '
    Write-Output "$([int][ViewType]::TaggingView) - Tagging view"
    Write-Output "$([int][ViewType]::RecipientsAndDocuments) - Recipients and documents view"
    [int]$startingView = Read-Host "Please make a selection"
} while (-not [ViewType]::IsDefined([ViewType], $startingView));


# Step 2. Create the envelope
# Create the document request body
#  document 1 (html) has tag **signature_1**
#  document 2 (docx) has tag /sn1/
#  document 3 (pdf) has tag /sn1/
#
#  The envelope has two recipients.
#  recipient 1 - signer
#  recipient 2 - cc
#
#  The envelope is created with "created" (draft) status.
#
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.

#ds-snippet-start:eSign11Step2
# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile
$doc2Base64 = New-TemporaryFile
$doc3Base64 = New-TemporaryFile

# Fetch docs and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\doc_1.html"))) > $doc1Base64
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_Battle_Plan_Trafalgar.docx"))) > $doc2Base64
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $doc3Base64

Write-Output "Sending the envelope request to DocuSign..."
Write-Output "The envelope has three documents. Processing time will be about 15 seconds."
Write-Output "Results:"

@{
    emailSubject = "Please sign this document set";
    documents    = @(
        @{
            documentBase64 = "$(Get-Content $doc1Base64)";
            name           = "Order acknowledgement";
            fileExtension  = "html";
            documentId     = "1";
        };
        @{
            documentBase64 = "$(Get-Content $doc2Base64)";
            name           = "Battle Plan";
            fileExtension  = "docx";
            documentId     = "2";
        };
        @{
            documentBase64 = "$(Get-Content $doc3Base64)";
            name           = "Lorem Ipsum";
            fileExtension  = "pdf";
            documentId     = "3";
        }; );
    recipients   = @{
        carbonCopies = @(
            @{
                email        = $CC_EMAIL;
                name         = $CC_NAME;
                recipientId  = "2";
                routingOrder = "2";
            };
        );
        signers      = @(
            @{
                email        = $SIGNER_EMAIL;
                name         = $SIGNER_NAME;
                recipientId  = "1";
                routingOrder = "1";
                tabs         = @{
                    signHereTabs = @(
                        @{
                            anchorString  = "**signature_1**";
                            anchorUnits   = "pixels";
                            anchorXOffset = "20";
                            anchorYOffset = "10";
                        };
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
    status       = "created";
} | ConvertTo-Json -Depth 32 >> $requestData

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response
#ds-snippet-end:eSign11Step2

# Step 3. Create the sender view
#ds-snippet-start:eSign11Step3
# pull out the envelopeId
$envelop = $response | Get-Content | ConvertFrom-Json
Write-Output "Envelope received: $envelop"
$envelopeId = $envelop.envelopeId

Write-Output "Requesting the sender view url"

# The returnUrl is normally your own web app. DocuSign will redirect
# the signer to returnUrl when the embedded sending completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from DocuSign
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/views/sender" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -Body (@{ returnUrl = "http://httpbin.org/get"; } | ConvertTo-Json) `
    -OutFile $response

$sendingObj = $response | Get-Content | ConvertFrom-Json
$sendingUrl = $sendingObj.url
# Next, we update the returned url if we want to start with the Recipient
# and Documents view
if ($startingView -eq [ViewType]::RecipientsAndDocuments) {
    $sendingUrl = $sendingUrl -replace "send=1", "send=0"
}
#ds-snippet-end:eSign11Step3

Write-Output "The embedded sending URL is ${sendingUrl}"
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser..."

Start-Process $sendingUrl

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64
Remove-Item $doc2Base64
Remove-Item $doc3Base64

Write-Output "Done."
