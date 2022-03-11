#Scheduled Sending
$apiUri = "https://demo.docusign.net/restapi"

# Send an envelope with one document

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

$accessToken = Get-Content .\config\ds_access_token.txt

#    Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

#  document 1 (pdf) has tag /sn1/
#
#  The envelope has one recipient.
#  recipient 1 - signer
#  The envelope will be scheduled to go to the signer.


# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$docBase64 = New-TemporaryFile

# Fetch docs and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $docBase64

Write-Output "Sending the envelope request to DocuSign..."
Write-Output "The envelope has one document. Processing time will be about 15 seconds."
Write-Output "Results:"

$ResumeDate = Read-Host "Please enter the future date for when you want to schedule this envelope as YYYY-MM-DD: "

# Create the envelope definition
# Step 2 start
@{
    emailSubject = "Please sign this document set";
    documents    = @(
        @{
            documentBase64 = "$(Get-Content $docBase64)";
            name           = "Lorem Ipsum";
            fileExtension  = "pdf";
            documentId     = "1";
        }; );
    workflow = @{
            scheduledSending =  @{
            rules =  @(
            @{
                resumeDate =  $ResumeDate;
            }; );
        };
    };
    recipients   = @{
        signers      = @(
            @{
                email        = $variables.SIGNER_EMAIL;
                name         = $variables.SIGNER_NAME;
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
    status       = "sent";
} | ConvertTo-Json -Depth 32 > $requestData
# Step 2 end

# Create and send the envelope
# Step 3 start
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
# Step 3 end

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId

# Save the envelope id for use by other scripts
Write-Output "EnvelopeId: $envelopeId"
Write-Output $envelopeId > .\config\ENVELOPE_ID

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $docBase64

Write-Output "Done."
