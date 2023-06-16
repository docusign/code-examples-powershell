# https://developers.docusign.com/docs/esign-rest-api/how-to/pause-workflow/

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$oAuthAccessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$SIGNER1_EMAIL = $variables.SIGNER_EMAIL
$SIGNER1_NAME = $variables.SIGNER_NAME
$SIGNER2_EMAIL = $variables.CC_EMAIL
$SIGNER2_NAME = $variables.CC_NAME

# Create temp files
$requestData = New-TemporaryFile
$response = New-TemporaryFile

# Step 2. Construct your API headers
#ds-snippet-start:eSign32Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:eSign32Step2

# Step 3. Construct the request body
#ds-snippet-start:eSign32Step3
@{
    documents    =
    @(
        @{
            "documentBase64" = "DQoNCg0KDQoJCVdlbGNvbWUgdG8gdGhlIERvY3VTaWduIFJlY3J1aXRpbmcgRXZlbnQNCgkJDQoJCQ0KCQlQbGVhc2UgU2lnbiBpbiENCgkJDQoJCQ0KCQk=";
            "documentId"     = "1";
            "fileExtension"  = "txt";
            "name"           = "Welcome"
        };
    );
    emailSubject = "EnvelopeWorkflowTest";
    "workflow"   =
    @{
        "workflowSteps" =
        @(
            @{
                "action"        = "pause_before";
                "triggerOnItem" = "routing_order";
                "itemId"        = "2"
            };
        );
    };
    recipients   = @{
        signers =
        @(
            @{
                email        = $SIGNER1_EMAIL;
                name         = $SIGNER1_NAME;
                recipientId  = "1";
                routingOrder = "1";
                tabs         = @{
                    signHereTabs = @(
                        @{
                            documentId = "1";
                            pageNumber = "1";
                            tabLabel   = "Sign Here";
                            xPosition  = "200";
                            yPosition  = "200"
                        };
                    );
                };
            };
            @{
                email        = $SIGNER2_EMAIL;
                name         = $SIGNER2_NAME;
                recipientId  = "2";
                routingOrder = "2";
                tabs         =
                @{
                    signHereTabs =
                    @(
                        @{
                            documentId = "1";
                            pageNumber = "1";
                            tabLabel   = "Sign Here";
                            xPosition  = "300";
                            yPosition  = "200"
                        };
                    );
                };
            };
        );
    };
    status       = "sent"
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:eSign32Step3

# Step 4. Call the eSignature API
#ds-snippet-start:eSign32Step4
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/envelopes"
Invoke-RestMethod `
    -Uri $uri `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $oAuthAccessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response
#ds-snippet-end:eSign32Step4

# Get EnvelopeID
$envelopeId = $($(Get-Content $response) | ConvertFrom-Json).envelopeId
$envelopeId > .\config\ENVELOPE_ID

Write-Output ""
Write-Output "Request: $(Get-Content -Raw $requestData)"
Write-Output "Envelope Id: $envelopeId"

# Delete temp files
Remove-Item $requestData
Remove-Item $response