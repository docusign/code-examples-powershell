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

# Send an envelope with a third-party notary service

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

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$docBase64 = New-TemporaryFile

$docPath = ".\demo_documents\World_Wide_Corp_Battle_Plan_Trafalgar.docx"

# Check the folder structure to switch paths for Quick ACG
if ((Test-Path $docPath) -eq $false) {
    $docPath = "..\demo_documents\World_Wide_Corp_Battle_Plan_Trafalgar.docx"
}

# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path $docPath))) > $docBase64

Write-Output "Sending the envelope request to Docusign..."
Write-Output "Please wait, this may take a few moments."

#ds-snippet-start:Notary4Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:Notary4Step2

# Concatenate the different parts of the request
#ds-snippet-start:Notary4Step3
@{
    emailSubject = "Please sign this document set";
    documents    = @(
        @{
            documentBase64 = "$(Get-Content $docBase64)";
            name           = "Order acknowledgement";
            fileExtension  = "html";
            documentId     = "1";
        };
    );
    recipients   = @{
        signers      = @(
            @{
                clientUserId = "1000";
                email        = $variables.SIGNER_EMAIL;
                name         = $variables.SIGNER_NAME;
                recipientId  = "2";
                routingOrder = "1";
                notaryId     = "1";
                tabs         = @{
                    signHereTabs = @(
                        @{
                            documentId  = "1";
                            xPosition   = "200";
                            yPosition   = "235";
                            pageNumber  = "1";
                        };
                        @{
                            stampType   = "stamp";
                            documentId  = "1";
                            xPosition   = "200";
                            yPosition   = "150";
                            pageNumber  = "1";
                        };
                    );
                };
            };
        );
        notaries = @(
            @{
                name            = "Notary";
                recipientId     = "1";
                routingOrder    = "1";
                tabs            = @{
                    notarySealTabs = @(
                        @{
                            xPosition   = "300";
                            yPosition   = "235";
                            documentId  = "1";
                            pageNumber  = "1";
                        };
                    );
                    signHereTabs = @(
                        @{
                            xPosition   = "300";
                            yPosition   = "150";
                            documentId  = "1";
                            pageNumber  = "1";
                        };
                    );
                };
                notaryType              = "remote";
                notarySourceType        = "thirdparty";
                notaryThirdPartyPartner = "onenotary";
                recipientSignatureProviders = @(
                    @{
                        sealDocumentsWithTabsOnly   = "false";
                        signatureProviderName       = "ds_authority_idv";
                        signatureProviderOptions    = @{};
                    };
                );
            };
        );
    };
    status       = "sent";
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:Notary4Step3

# Step 3. Call Docusign to create the envelope
#ds-snippet-start:Notary4Step4
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers $headers `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response
#ds-snippet-end:Notary4Step4

Write-Output "Response: $(Get-Content -Raw $response)"

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
Write-Output "EnvelopeId: $envelopeId"

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $docBase64

Write-Output "Done."