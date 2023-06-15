#SMS Delivery
$apiUri = "https://demo.docusign.net/restapi"

# Send an envelope with three documents

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

$accessToken = Get-Content .\config\ds_access_token.txt

#    Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

#  document 1 (html) has tag **signature_1**
#  document 2 (docx) has tag /sn1/
#  document 3 (pdf) has tag /sn1/
#
#  The envelope has two recipients.
#  recipient 1 - signer
#  recipient 2 - cc
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.


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

# Step 2. Create the envelope definition
$SMSCountryPrefix = Read-Host "Please enter a country phone number prefix for the Signer: "
$SMSNumber = Read-Host "Please enter an SMS-enabled Phone number for the Signer: "
$SMSCCCountryPrefix = Read-Host "Please enter a country phone number prefix for the Carbon Copied recipient: "
$SMSNumberCC = Read-Host "Please enter an SMS-enabled Phone number for the Carbon Copied recipient: "

#ds-snippet-start:eSign37Step2
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
                phoneNumber = @{
                    countryCode =  $SMSCCCountryPrefix;
                    number = $SMSNumberCC;
                }
                name         = $variables.CC_NAME;
                recipientId  = "2";
                routingOrder = "2";
                deliveryMethod = "SMS";
            };
        );

        signers      = @(
            @{
                phoneNumber = @{
                    countryCode =  $SMSCountryPrefix;
                    number = $SMSNumber;
                }
                name         = $variables.SIGNER_NAME;
                recipientId  = "1";
                routingOrder = "1";
                deliveryMethod = "SMS";
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
    status       = "sent";
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:eSign37Step2

Write-Output "Sending the envelope request to DocuSign..."
Write-Output "The envelope has three documents. Processing time will be about 15 seconds."
Write-Output "Results:"
Write-Output $requestData

# Step 3. Create and send the envelope
# Create and send the envelope
#ds-snippet-start:eSign37Step3
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
#ds-snippet-end:eSign37Step3

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId

# Save the envelope id for use by other scripts
Write-Output "EnvelopeId: $envelopeId"
Write-Output $envelopeId > .\config\ENVELOPE_ID

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64
Remove-Item $doc2Base64
Remove-Item $doc3Base64

Write-Output "Done."
