$apiUri = "https://demo.docusign.net/restapi"

# Send an envelope and set document visibility

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json


# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

#  document 1 (html) has tag **signature_1**
#  document 2 (docx) has tag /sn1/
#  document 3 (pdf) has tag /sn1/
#
#  The envelope has two recipients.
#  recipient 1 - signer 1
#  recipient 2 - signer 2
#  recipient 3 - cc
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.


# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile
$doc2Base64 = New-TemporaryFile
$doc3Base64 = New-TemporaryFile

$SIGNER1_EMAIL = Read-Host 'Please enter signer #1 email address'
$SIGNER1_NAME = Read-Host 'Please enter signer #1 name'
$SIGNER2_EMAIL = Read-Host 'Please enter signer #2 email address'
$SIGNER2_NAME = Read-Host 'Please enter signer #2 name'
$CC_EMAIL = Read-Host 'Please enter carbon copy email address'
$CC_NAME = Read-Host 'Please enter carbon copy name'

#ds-snippet-start:eSign40Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:eSign40Step2


# Fetch docs and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\doc_1.html"))) > $doc1Base64
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_Battle_Plan_Trafalgar.docx"))) > $doc2Base64
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $doc3Base64

Write-Output "Sending the envelope request to DocuSign..."
Write-Output "The envelope has three documents. Processing time will be about 15 seconds."
Write-Output "Results:"

# Concatenate the different parts of the request
#ds-snippet-start:eSign40Step3
@{
    emailSubject = "Please sign this document set";
    enforceSignerVisibility = "true";
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
                recipientId  = "3";
                routingOrder = "3";
            };
        );
        signers      = @(
            @{
                email        = $SIGNER1_EMAIL;
                name         = $SIGNER1_NAME;
                recipientId  = "1";
                routingOrder = "1";
                excludedDocuments = @(2, 3)
                tabs         = @{
                    signHereTabs = @(
                        @{
                            anchorString  = "**signature_1**";
                            anchorUnits   = "pixels";
                            anchorXOffset = "20";
                            anchorYOffset = "10";
                        };
                    );
                };
            };
            @{
                email        = $SIGNER2_EMAIL;
                name         = $SIGNER2_NAME;
                recipientId  = "2";
                routingOrder = "2";
                excludedDocuments = @(1)
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
#ds-snippet-end:eSign40Step3

# Step 3. Create and send the envelope'
#ds-snippet-start:eSign40Step4
try {
    Invoke-RestMethod `
        -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
        -Method 'POST' `
        -Headers $headers `
        -InFile (Resolve-Path $requestData).Path `
        -OutFile $response
#ds-snippet-end:eSign40Step4

    Write-Output "Response: $(Get-Content -Raw $response)"

    # pull out the envelopeId
    $envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId

    Write-Output "EnvelopeId: $envelopeId"
}
catch {
    $errorMessage = $_.ErrorDetails.Message
    Write-Host $errorMessage
    Write-Host ""

    if ( $errorMessage.Contains("ACCOUNT_LACKS_PERMISSIONS") ) {
        Write-Host "See https://developers.docusign.com/docs/esign-rest-api/how-to/set-document-visibility in the DocuSign Developer Center for instructions on how to enable document visibility in your developer account."
    }
}

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64
Remove-Item $doc2Base64
Remove-Item $doc3Base64

Write-Output "Done."
