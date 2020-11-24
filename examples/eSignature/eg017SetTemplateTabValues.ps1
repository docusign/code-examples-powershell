$apiUri = "https://demo.docusign.net/restapi"

# Set Template-based Envelope Tab Data

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile

# Check that we have a template ID
if (Test-Path .\config\TEMPLATE_ID) {
    $templateId = Get-Content .\config\TEMPLATE_ID
}
else {
    Write-Output "PROBLEM: A templateId is needed. Fix: execute step 8 - Create_Template"
    exit 0
}

Write-Output "Sending the envelope request to DocuSign..."
# Tabs and custom fields shown in the request body on step 4
# Step 4. Construct the request body
@{
    customFields  = @{
        textCustomFields = @(
            @{
                name     = "app metadata item";
                required = "false";
                show     = "true";
                value    = "1234567";
            };
        );
    };
    templateRoles = @(
        @{
            clientUserId = "1000";
            email        = $variables.SIGNER_EMAIL;
            name         = $variables.SIGNER_NAME;
            roleName     = "signer";
            tabs         = @{
                checkboxTabs   = @(
                    @{
                        selected = "true";
                        tabLabel = "ckAuthorization";
                    };
                    @{
                        selected = "true";
                        tabLabel = "ckAgreement";
                    };
                );
                listTabs       = @(
                    @{
                        documentId = "1";
                        pageNumber = "1";
                        tabLabel   = "list";
                        value      = "green";
                    };
                );
                radioGroupTabs = @(
                    @{
                        groupName = "radio1";
                        radios    = @(
                            @{
                                selected = "true";
                                value    = "white";
                            };
                        );
                    };
                );
                textTabs       = @(
                    @{
                        tabLabel = "text";
                        value    = "Jabberywocky!";
                    };
                    @{
                        bold       = "true";
                        documentId = "1";
                        font       = "helvetica";
                        fontSize   = "size14";
                        height     = "23";
                        locked     = "false";
                        pageNumber = "1";
                        required   = "false";
                        tabId      = "name";
                        tabLabel   = "added text field";
                        value      = $variables.SIGNER_NAME;
                        width      = "84";
                        xPosition  = "280";
                        yPosition  = "172";
                    };
                );
            };
        };
        @{
            email    = $variables.CC_EMAIL;
            name     = $variables.CC_NAME;
            roleName = "cc";
        };
    );
    status        = "Sent";
    templateId    = "$templateId";
} | ConvertTo-Json -Depth 32 > $requestData

# Step 5. Call the eSignature REST API
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response

Write-Output "Response:"
Get-Content $response

# pull out the envelope ID
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
Write-Output "EnvelopeId: $envelopeId"

# Step 6. Create a recipient view (an embedded signing view)
#         that the signer will directly open in their browser to sign
#
# The return URL is normally your own web app. DocuSign will redirect
# the signer to the return URL when the DocuSign signing completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from DocuSign

Write-Output "Requesting the url for the embedded signing..."

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

Write-Output "Response:"
Get-Content $response

$signingUrl = $(Get-Content $response | ConvertFrom-Json).url

Write-Output "The embedded signing URL is $signingUrl"
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser..."
Start-Process $signingUrl

# cleanup
Remove-Item $requestData
Remove-Item $response

Write-Output "Done."
