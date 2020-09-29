# Embedded Signing Ceremony from template with added document

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Configuration
# 1. Search for and update '{USER_EMAIL}' and '{USER_FULLNAME}'.
#    They occur and re-occur multiple times below.
# 2. Obtain an OAuth access token from
#    https://developers.docusign.com/oauth-token-generator
$accessToken = Get-Content .\config\ds_access_token.txt

# 3. Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

$apiUri = "https://demo.docusign.net/restapi"

# Check that we have a template id
if (Test-Path .\config\TEMPLATE_ID) {
    $templateId = Get-Content .\config\TEMPLATE_ID
}
else {
    Write-Output "`nPROBLEM: A templateId is needed. Fix: execute step 8 - Create_Template`n"
    exit 0
}

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile

# ***DS.snippet.0.start
# Fetch docs and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\added_document.html"))) > $doc1Base64

Write-Output ""
Write-Output "Sending the envelope request to DocuSign..."
Write-Output "A template is used, it has one document. A second document will be"
Write-Output "added by using Composite Templates"

# Concatenate the different parts of the request
#  document 1 (html) has tag **signature_1**
@{
    compositeTemplates = @(
        @{
            compositeTemplateId = "1";
            inlineTemplates     = @(
                @{
                    recipients = @{
                        carbonCopies = @(
                            @{
                                email       = $variables.CC_EMAIL;
                                name        = $variables.CC_NAME;
                                recipientId = "2";
                                roleName    = "cc";
                            };
                        );
                        signers      = @(
                            @{
                                clientUserId = "1000";
                                email        = $variables.SIGNER_EMAIL;
                                name         = $variables.SIGNER_NAME;
                                recipientId  = "1";
                                roleName     = "signer";
                            };
                        );
                    };
                    sequence   = "1";
                };
            );
            serverTemplates     = @(
                @{
                    sequence   = "1";
                    templateId = "$templateId";
                };
            );
        };
        @{
            compositeTemplateId = "2";
            document            = @{
                documentBase64 = "$(Get-Content $doc1Base64)";
                documentId     = "1";
                fileExtension  = "html";
                name           = "Appendix 1--Sales order";
            };
            inlineTemplates     = @(
                @{
                    recipients = @{
                        carbonCopies = @(
                            @{
                                email       = $variables.CC_EMAIL;
                                name        = $variables.CC_NAME;
                                recipientId = "2";
                                roleName    = "cc";
                            };
                        );
                        signers      = @(
                            @{
                                email       = $variables.SIGNER_EMAIL;
                                name        = $variables.SIGNER_NAME;
                                recipientId = "1";
                                roleName    = "signer";
                                tabs        = @{
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
                        );
                    };
                    sequence   = "2";
                };
            );
        };
    );
    status             = "sent";
} | ConvertTo-Json -Depth 32 > $requestData

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
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
Write-Output ""

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
Write-Output "EnvelopeId: $envelopeId"
Write-Output ""

# Step 2. Create a recipient view (a signing ceremony view)
#         that the signer will directly open in their browser to sign.
#
# The returnUrl is normally your own web app. DocuSign will redirect
# the signer to returnUrl when the signing ceremony completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from DocuSign
Write-Output ""
Write-Output "Requesting the url for the signing ceremony..."

@{
    returnUrl            = "http://httpbin.org/get";
    authenticationMethod = "none";
    email                = $variables.SIGNER_EMAIL;
    userName             = $variables.SIGNER_NAME;
    clientUserId         = 1000;
} | ConvertTo-Json -Depth 32 > $requestData

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/views/recipient" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path`
    -OutFile $response

Write-Output ""
Write-Output "Response:"
Get-Content $response
Write-Output ""

$signingCeremonyUrl = $(Get-Content $response | ConvertFrom-Json).url
# ***DS.snippet.0.end

Write-Output "The signing ceremony URL is $signingCeremonyUrl`n"
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser...`n"
Start-Process $signingCeremonyUrl

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64

Write-Output ""
Write-Output "Done."
Write-Output ""