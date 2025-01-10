#Delayed Routing
$apiUri = "https://demo.docusign.net/restapi"

# Send an envelope with one document

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

$accessToken = Get-Content .\config\ds_access_token.txt

#    Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

#  document (pdf) has tag /sn1/
#
#  The envelope has two recipients.
#  recipient 1 - signer
#  recipient 2 - signer
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.


# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$docBase64 = New-TemporaryFile

# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $docBase64

Write-Output "Sending the envelope request to Docusign..."
Write-Output "The envelope has three documents. Processing time will be about 15 seconds."
Write-Output "Results:"

$Signer2Email = Read-Host "Please enter the email address for the second signer: "
$Signer2Name = Read-Host "Please enter the name for the second signer: "
$DelayInHours= Read-Host "Please enter the delay (in hours): "
$DelayTimeSpan = New-TimeSpan -Hours $DelayInHours -Minutes 0

#ds-snippet-start:eSign36Step2
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
        workflowSteps = @(
            @{
                action = "pause_before";
                triggerOnItem = "routing_order";
                itemId = "2";
                delayedRouting = @{
                    rules = @(
                        @{
                            delay = $DelayTimeSpan.ToString();
                        };
                    );
                };
            };
        );
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
                            anchorString  = "/sn1/";
                            anchorUnits   = "pixels";
                            anchorXOffset = "20";
                            anchorYOffset = "10";
                        };
                    );
                };
            };
            @{
                email        = $Signer2Email;
                name         = $Signer2Name;
                recipientId  = "2";
                routingOrder = "2";
                tabs         = @{
                    signHereTabs = @(
                        @{
                            anchorString  = "/sn1/";
                            anchorUnits   = "pixels";
                            anchorXOffset = "120";
                            anchorYOffset = "10";
                        };
                    );
                };
            };
        );
    };
    status       = "sent";
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:eSign36Step2

# Create and send the envelope
#ds-snippet-start:eSign36Step3
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response
#ds-snippet-end:eSign36Step3

Write-Output "Response: $(Get-Content -Raw $response)"

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
