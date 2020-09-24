# Create a template. First, the account's templates are listed.
# If one of the templates is named "Example Signer and CC template"
# then the template will not be created.

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

$apiUri = "https://demo.docusign.net/restapi"

# ***DS.snippet.0.start
# Step 1. List the account's templates
Write-Output ""
Write-Output "Checking to see if the template already exists in your account..."
Write-Output ""

$templateName = "Example Signer and CC template"
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
$templateId = $(Get-Content $response | ConvertFrom-Json).envelopeTemplates.templateId

Write-Output "Did we find any templateIds?: $templateId"

if (-not ([string]::IsNullOrEmpty($templateId))) {
    Write-Output ""
    Write-Output "Your account already includes the '${templateName}' template."
    # Save the template id for use by other scripts
    Write-Output "${templateId}" > .\config\TEMPLATE_ID
    Remove-Item $response
    Write-Output ""
    Write-Output "Done."
    Write-Output ""
    exit 0
}

# Step 2. Create the template programmatically
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

Write-Output ""
Write-Output "Sending the template create request to DocuSign..."
Write-Output ""

# Fetch document and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_fields.pdf"))) > $doc1Base64

# Concatenate the different parts of the request
@{
    documents                  = @(
        @{
            documentBase64 = "$(Get-Content $doc1Base64)";
            documentId     = "1";
            fileExtension  = "pdf";
            name           = "Lorem Ipsum";
        };
    );
    emailSubject               = "Please sign this document";
    envelopeTemplateDefinition = @{
        description = "Example template created via the API";
        name        = "Example Signer and CC template";
        shared      = "false";
    };
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
                        @{
                            documentId = "1"; font = "helvetica";
                            fontSize = "size14"; height = 23;
                            pageNumber = "1"; required = "false";
                            tabLabel = "numbersOnly"; width = 84;
                            xPosition = "153"; yPosition = "260";
                        };
                    );
                };
            };
        );
    };
    status = "created";
} | ConvertTo-Json -Depth 32 > $requestData

<# $((Get-Content -path $requestDataTemp -Raw) -replace 'doc1Base64', `
    $(Get-Content $doc1Base64)) > $requestData #>

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/templates" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response

Write-Output ""
Write-Output "Results:"
Get-Content $response

# pull out the template id
$templateId = $(Get-Content $response | ConvertFrom-Json).templateId
# ***DS.snippet.0.end

Write-Output ""
Write-Output "Template '${templateName}' was created! Template ID ${templateId}."
# Save the template id for use by other scripts
Write-Output ${templateId} > .\config\TEMPLATE_ID

# cleanup
Remove-Item $requestData
Remove-Item $requestDataTemp
Remove-Item $response
Remove-Item $doc1Base64

Write-Output ""
Write-Output "Done."
Write-Output ""
