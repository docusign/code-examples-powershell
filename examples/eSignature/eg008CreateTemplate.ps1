$apiUri = "https://demo.docusign.net/restapi"

# Create a template. First, the account's templates are listed.
# If one of the templates is named "Example Signer and CC template"
# then the template will not be created.

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# ***DS.snippet.0.start
# List the account's templates
Write-Output "Checking to see if the template already exists in your account..."

$templateName = "Example Signer and CC template v2"
$response = New-TemporaryFile

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/templates" `
    -Method 'GET' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -Body @{ 'search_text' = $templateName } `
    -OutFile $response

# pull out the templateId if it was returned
$templateIds = $(Get-Content $response | ConvertFrom-Json).envelopeTemplates.templateId

Write-Output "Did we find any templateIds?: $templateIds"

if (-not ([string]::IsNullOrEmpty($templateIds))) {
    Write-Output "Your account already includes the '${templateName}' template."
    # Save the template id for use by other scripts
    $templateId = $templateIds -split ' ' | Select-Object -First 1
    Write-Output "${templateId}" > .\config\TEMPLATE_ID
    Remove-Item $response
    Write-Output "Done."
    exit 0
}

# Step 2. Create a template
#
#  The envelope has two recipients.
#  recipient 1 - signer
#  recipient 2 - cc
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.

# temp files:
$requestData = New-TemporaryFile
$requestDataTemp = New-TemporaryFile
$doc1Base64 = New-TemporaryFile

Write-Output "Sending the template create request to Docusign..."

# Fetch document and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_fields.pdf"))) > $doc1Base64

# Concatenate the different parts of the request
#ds-snippet-start:eSign8Step2
@{
    description = "Example template created via the eSignature API";
    name        = "Example Signer and CC template v2";
    shared      = "false";
    documents                  = @(
        @{
            documentBase64 = "$(Get-Content $doc1Base64)";
            documentId     = "1";
            fileExtension  = "pdf";
            name           = "Lorem Ipsum";
        };
    );
    emailSubject               = "Please sign this document";
    recipients                 = @{
        carbonCopies = @(
            @{recipientId = "2"; roleName = "cc"; routingOrder = "2"; };
        );
        signers      = @(
            @{
                recipientId = "1"; roleName = "signer"; routingOrder = "1";
                tabs = @{
                    checkboxTabs   = @(
                        @{
                            documentId = "1"; pageNumber = "1";
                            tabLabel = "ckAuthorization"; xPosition = "75";
                            yPosition = "417";
                        };
                        @{
                            documentId = "1"; pageNumber = "1";
                            tabLabel = "ckAuthentication"; xPosition = "75";
                            yPosition = "447";
                        };
                        @{
                            documentId = "1"; pageNumber = "1";
                            tabLabel = "ckAgreement"; xPosition = "75";
                            yPosition = "478";
                        };
                        @{
                            documentId = "1"; pageNumber = "1";
                            tabLabel = "ckAcknowledgement"; xPosition = "75";
                            yPosition = "508";
                        };
                    );
                    listTabs       = @(
                        @{
                            documentId = "1"; font = "helvetica";
                            fontSize = "size14";
                            listItems = @(
                                @{text = "Red"; value = "red"; };
                                @{text = "Orange"; value = "orange"; };
                                @{text = "Yellow"; value = "yellow"; };
                                @{text = "Green"; value = "green"; };
                                @{text = "Blue"; value = "blue"; };
                                @{text = "Indigo"; value = "indigo"; };
                                @{text = "Violet"; value = "violet"; };
                            );
                            pageNumber = "1"; required = "false";
                            tabLabel = "list"; xPosition = "142";
                            yPosition = "291";
                        };
                    );
                    radioGroupTabs = @(
                        @{
                            documentId = "1"; groupName = "radio1";
                            radios = @(
                                @{
                                    pageNumber = "1"; required = "false";
                                    value = "white"; xPosition = "142";
                                    yPosition = "384";
                                };
                                @{
                                    pageNumber = "1"; required = "false";
                                    value = "red"; xPosition = "74";
                                    yPosition = "384";
                                };
                                @{
                                    pageNumber = "1"; required = "false";
                                    value = "blue"; xPosition = "220";
                                    yPosition = "384";
                                };
                            );
                        };
                    );
                    signHereTabs   = @(
                        @{
                            documentId = "1"; pageNumber = "1";
                            xPosition = "191"; yPosition = "148";
                        };
                    );
                    textTabs       = @(
                        @{
                            documentId = "1"; font = "helvetica";
                            fontSize = "size14"; height = 23;
                            pageNumber = "1"; required = "false";
                            tabLabel = "text"; width = 84;
                            xPosition = "153"; yPosition = "230";
                        };
                    );
                    numericalTabs       = @(
                        @{
                            ValidationType = "Currency";
                            documentId = "1"; font = "helvetica";
                            fontSize = "size14"; height = 23;
                            pageNumber = "1"; required = "false";
                            tabLabel = "numericalCurrency"; width = 84;
                            xPosition = "153"; yPosition = "230";
                        };
                    );
                };
            };
        );
    };
    status                     = "created";
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:eSign8Step2

#ds-snippet-start:eSign8Step3
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/templates" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response
#ds-snippet-end:eSign8Step3

Write-Output "Results:"
Get-Content $response

# pull out the template id
$templateId = $(Get-Content $response | ConvertFrom-Json).templateId
# ***DS.snippet.0.end

Write-Output "Template '${templateName}' was created! Template ID ${templateId}."
# Save the template id for use by other scripts
Write-Output ${templateId} > .\config\TEMPLATE_ID

# cleanup
Remove-Item $requestData
Remove-Item $requestDataTemp
Remove-Item $response
Remove-Item $doc1Base64

Write-Output "Done."
