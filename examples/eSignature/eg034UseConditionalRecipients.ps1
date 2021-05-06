# https://developers.docusign.com/docs/esign-rest-api/how-to/use-conditional-recipients/

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$oAuthAccessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Get required environment variables from .\config\settings.json file
$configFile = ".\config\settings.json"
$config = Get-Content $configFile -Raw | ConvertFrom-Json

if($config.SIGNER_NOT_CHECKED_EMAIL  -eq "{SIGNER_NOT_CHECKED_EMAIL}" ){
    $config.SIGNER_NOT_CHECKED_EMAIL = Read-Host "Enter an email address to route to when the checkbox is not checked"
    $config.SIGNER_NOT_CHECKED_NAME = Read-Host "Enter a name to route to when the checkbox is not checked"
    Write-Output ""
    write-output $config | ConvertTo-Json | Set-Content $configFile
    }

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$SIGNER1_EMAIL = $variables.SIGNER_EMAIL
$SIGNER1_NAME = $variables.SIGNER_NAME
$SIGNER_WHEN_CHECKED_EMAIL = $variables.CC_EMAIL
$SIGNER_WHEN_CHECKED_NAME = $variables.CC_NAME
$SIGNER_NOT_CHECKED_EMAIL = $variables.SIGNER_NOT_CHECKED_EMAIL
$SIGNER_NOT_CHECKED_NAME = $variables.SIGNER_NOT_CHECKED_NAME

# Step 2. Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

# Create temp files
$requestData = New-TemporaryFile
$response = New-TemporaryFile

# Step 3. Construct the request body
@{
    documents    =
    @(
        @{
            documentBase64 = "VGhhbmtzIGZvciByZXZpZXdpbmcgdGhpcyEKCldlJ2xsIG1vdmUgZm9yd2FyZCBhcyBzb29uIGFzIHdlIGhlYXIgYmFjay4=";
            documentId     = "1";
            fileExtension  = "txt";
            name           = "Welcome"
        };
    );
    emailSubject = "ApproveIfChecked";
    workflow     =
    @{
        workflowSteps =
        @(
            @{
                action           = "pause_before";
                triggerOnItem    = "routing_order";
                itemId           = 2;
                status           = "pending";
                recipientRouting =
                @{
                    rules =
                    @{
                        conditionalRecipients =
                        @(
                            @{
                                recipientId    = 2;
                                order          = "0";
                                recipientGroup =
                                @{
                                    groupName    = "Approver";
                                    groupMessage = "Members of this group approve a workflow";
                                    recipients   =
                                    @(
                                        @{
                                            recipientLabel = "signer2a";
                                            name           = $SIGNER_NOT_CHECKED_NAME;
                                            roleName       = "Signer when not checked";
                                            email          = $SIGNER_NOT_CHECKED_EMAIL
                                        };
                                        @{
                                            recipientLabel = "signer2b";
                                            name           = $SIGNER_WHEN_CHECKED_NAME;
                                            roleName       = "Signer when checked";
                                            email          = $SIGNER_WHEN_CHECKED_EMAIL
                                        };
                                    );
                                };
                                conditions     =
                                @(
                                    @{
                                        recipientLabel = "signer2a";
                                        order          = 1;
                                        filters        =
                                        @(
                                            @{
                                                scope       = "tabs";
                                                recipientId = "1";
                                                tabId       = "ApprovalTab";
                                                operator    = "equals";
                                                value       = "false";
                                                tabType     = "checkbox";
                                                tabLabel    = "ApproveWhenChecked"
                                            };
                                        );
                                    };
                                    @{
                                        recipientLabel = "signer2b";
                                        order          = 2;
                                        filters        =
                                        @(
                                            @{
                                                scope       = "tabs";
                                                recipientId = "1";
                                                tabId       = "ApprovalTab";
                                                operator    = "equals";
                                                value       = "true";
                                                tabType     = "checkbox";
                                                tabLabel    = "ApproveWhenChecked"
                                            };
                                        );
                                    };
                                );
                            };
                        );
                    };
                };
            };
        );
    };
    recipients   =
    @{
        signers =
        @(
            @{
                email        = $SIGNER1_EMAIL;
                name         = $SIGNER1_NAME;
                recipientId  = "1";
                routingOrder = "1";
                roleName     = "Purchaser";
                tabs         =
                @{
                    signHereTabs =
                    @(
                        @{
                            name       = "SignHere";
                            documentId = "1";
                            pageNumber = "1";
                            tabLabel   = "PurchaserSignature";
                            xPosition  = "200";
                            yPosition  = "200"
                        };
                    );
                    checkboxTabs =
                    @(
                        @{
                            name       = "ClickToApprove";
                            selected   = "false";
                            documentId = "1";
                            pageNumber = "1";
                            tabLabel   = "ApproveWhenChecked";
                            xPosition  = "50";
                            yPosition  = "50"
                        };
                    );
                };
            };
            @{
                email        = "placeholder@example.com";
                name         = "Approver";
                recipientId  = "2";
                routingOrder = "2";
                roleName     = "Approver";
                tabs         =
                @{
                    signHereTabs =
                    @(
                        @{
                            name        = "SignHere";
                            documentId  = "1";
                            pageNumber  = "1";
                            recipientId = "2";
                            tabLabel    = "ApproverSignature";
                            xPosition   = "300";
                            yPosition   = "200"
                        };
                    );
                };
            };
        );
    };
    status       = "Sent"
} | ConvertTo-Json -Depth 32 > $requestData

# Step 4. Call the eSignature API
try {
    $uri = "https://demo.docusign.net/restapi/v2.1/accounts/${APIaccountId}/envelopes"
    Invoke-RestMethod `
        -Uri $uri `
        -Method 'POST' `
        -Headers @{
        'Authorization' = "Bearer $oAuthAccessToken";
        'Content-Type'  = "application/json";
    } `
        -InFile (Resolve-Path $requestData).Path `
        -OutFile $response

    Write-Output "Response: $(Get-Content -Raw $response)"
}
catch [System.Net.WebException] {
    $errorCode = $($_.ErrorDetails | ConvertFrom-Json).errorCode
    if ( $errorCode -eq "WORKFLOW_UPDATE_RECIPIENTROUTING_NOT_ALLOWED" ) {
        Write-Output ""
        Write-Output "The following Error happened: WORKFLOW_UPDATE_RECIPIENTROUTING_NOT_ALLOWED"
        Write-Output "Please contact DocuSign support..."
    }
    else {
        $_
    }
}
catch {
    Write-Output $_
}

# Delete temp files
Remove-Item $requestData
Remove-Item $response
