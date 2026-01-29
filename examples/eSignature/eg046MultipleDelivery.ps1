#Email and SMS or WhatsApp Delivery
$apiUri = "https://demo.docusign.net/restapi"

$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$accessToken = Get-Content .\config\ds_access_token.txt
$accountId = Get-Content .\config\API_ACCOUNT_ID

$doc1Base64 = New-TemporaryFile
$doc2Base64 = New-TemporaryFile
$doc3Base64 = New-TemporaryFile

[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\doc_1.html"))) > $doc1Base64
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_Battle_Plan_Trafalgar.docx"))) > $doc2Base64
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $doc3Base64

Write-Host "Choose a message delivery type:"
Write-Host "1 - SMS"
Write-Host "2 - WhatsApp"

do {
    $choice = Read-Host "Select 1 or 2"
} while ($choice -notin @("1", "2"))

if ($choice -eq "1") {
    $deliveryMethod = "SMS"
}
else {
    $deliveryMethod = "WhatsApp"
}

$signerCountry = Read-Host "Please enter a country phone number prefix for the Signer"
$signerNumber = Read-Host "Please enter a Mobile number for the Signer"

$ccCountry = Read-Host "Please enter a country phone number prefix for the Carbon Copied recipient"
$ccNumber = Read-Host "Please enter a Mobile number for the Carbon Copied recipient"

#ds-snippet-start:eSign46Step2
$requestData = New-TemporaryFile
$response = New-TemporaryFile

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
        };
    );
    recipients   = @{
        carbonCopies = @(
            @{
                additionalNotifications = @(
                    @{
                        secondaryDeliveryMethod = $deliveryMethod;
                        phoneNumber = @{
                            countryCode = $ccCountry;
                            number      = $ccNumber;
                        };
                    };
                );
                name           = $variables.CC_NAME;
                email          = $variables.CC_EMAIL;
                recipientId    = "2";
                routingOrder   = "2";
                deliveryMethod = "Email";
            };
        );
        signers = @(
            @{
                additionalNotifications = @(
                    @{
                        secondaryDeliveryMethod = $deliveryMethod;
                        phoneNumber = @{
                            countryCode = $signerCountry;
                            number      = $signerNumber;
                        };
                    };
                );
                name             = $variables.SIGNER_NAME;
                email            = $variables.SIGNER_EMAIL;
                recipientId      = "1";
                routingOrder     = "1";
                deliveryMethod   = "Email";
                tabs             = @{
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
#ds-snippet-end:eSign46Step2

Write-Output "Sending the envelope request to Docusign..."
Write-Output "The envelope has three documents. Processing time will be about 15 seconds."
Write-Output "Results:"
Write-Output $requestData

try {
    #ds-snippet-start:eSign46Step3
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

    $envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
    #ds-snippet-end:eSign46Step3
    Write-Output "Response: $response"

    $envelopeId = $($response.envelopeId)

    Write-Output "EnvelopeId: $envelopeId"
    Write-Output $envelopeId > .\config\ENVELOPE_ID
} catch {
    Write-Error (
        "This account does not have sufficient permissions to send envelopes via SMS. " +
        "To enable multi-channel delivery, please contact DocuSign Support: " +
        "https://developers.docusign.com/support"
    )
    exit 1
}

Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64
Remove-Item $doc2Base64
Remove-Item $doc3Base64

Write-Output "Done."
