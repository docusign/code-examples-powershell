# Send an envelope including an order form with payment by credit card
#
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

# 4. Log in to DocuSign Admin and from the top 
#    navigation, select Admin. From there look 
#    to the left under INTEGRATIONS and select 
#    Payments to retrieve your Gateway account ID. 

$apiUri = "https://demo.docusign.net/restapi"

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile

# ***DS.snippet.0.start
# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\order_form.html"))) > $doc1Base64

Write-Output ""
Write-Output "Sending the envelope request to DocuSign..."

# Concatenate the different parts of the request
@{
    emailSubject = "Please complete your order";
    documents    = @(
        @{
            documentBase64 = "$(Get-Content $doc1Base64)";
            name = "Order form"; fileExtension = "html";
            documentId = "1";
        };
    );
    recipients   = @{
        carbonCopies = @(
            @{
                email = $variables.CC_EMAIL; name = $variables.CC_NAME;
                recipientId = "2"; routingOrder = "2";
            }
        );
        signers      = @(
            @{
                email = $variables.SIGNER_EMAIL; name = $variables.SIGNER_NAME;
                recipientId = "1"; routingOrder = "1";
                tabs = @{
                    formulaTabs  = @(
                        @{
                            anchorString = "/l1e/"; anchorUnits = "pixels";
                            anchorXOffset = "105"; anchorYOffset = "-8";
                            disableAutoSize = "false"; font = "helvetica";
                            fontSize = "size11"; formula = "[l1q] * 5";
                            locked = "true"; required = "true";
                            roundDecimalPlaces = "0"; tabLabel = "l1e";
                        };
                        @{
                            anchorString = "/l2e/"; anchorUnits = "pixels";
                            anchorXOffset = "105"; anchorYOffset = "-8";
                            disableAutoSize = "false"; font = "helvetica";
                            fontSize = "size11"; formula = "[l2q] * 150";
                            locked = "true"; required = "true";
                            roundDecimalPlaces = "0"; tabLabel = "l2e";
                        };
                        @{
                            anchorString = "/l3t/"; anchorUnits = "pixels";
                            anchorXOffset = "50"; anchorYOffset = "-8";
                            bold = "true"; disableAutoSize = "false";
                            font = "helvetica"; fontSize = "size12";
                            formula = "[l1e] + [l2e]"; locked = "true";
                            required = "true"; roundDecimalPlaces = "0";
                            tabLabel = "l3t";
                        };
                        @{
                            documentId = "1"; formula = "([l1e] + [l2e]) * 100";
                            hidden = "true"; locked = "true";
                            pageNumber = "1";
                            paymentDetails = @{
                                currencyCode       = "USD";
                                gatewayAccountId   = $GATEWAY_ACCOUNT_ID;
                                gatewayDisplayName = "Stripe";
                                gatewayName        = "stripe";
                                lineItems          = @(
                                    @{
                                        amountReference = "l1e";
                                        description     = "$5 each";
                                        name            = "Harmonica";
                                    };
                                    @{
                                        amountReference = "l2e";
                                        description     = "$150 each";
                                        name            = "Xylophone";
                                    };
                                );
                            };
                            required = "true"; roundDecimalPlaces = "0";
                            tabLabel = "payment";
                            xPosition = "0"; yPosition = "0";
                        };
                    );
                    listTabs     = @(
                        @{
                            anchorString = "/l1q/"; anchorUnits = "pixels";
                            anchorXOffset = "0"; anchorYOffset = "-10";
                            font = "helvetica"; fontSize = "size11";
                            listItems = @(
                                @{text = "none"; value = "0"; };
                                @{text = "1"; value = "1"; };
                                @{text = "2"; value = "2"; };
                                @{text = "3"; value = "3"; };
                                @{text = "4"; value = "4"; };
                                @{text = "5"; value = "5"; };
                                @{text = "6"; value = "6"; };
                                @{text = "7"; value = "7"; };
                                @{text = "8"; value = "8"; };
                                @{text = "9"; value = "9"; };
                                @{text = "10"; value = "10"; };
                            );
                            required = "true"; tabLabel = "l1q";
                        };
                        @{
                            anchorString = "/l2q/"; anchorUnits = "pixels";
                            anchorXOffset = "0"; anchorYOffset = "-10";
                            font = "helvetica"; fontSize = "size11";
                            listItems = @(
                                @{text = "none"; value = "0"; };
                                @{text = "1"; value = "1"; };
                                @{text = "2"; value = "2"; };
                                @{text = "3"; value = "3"; };
                                @{text = "4"; value = "4"; };
                                @{text = "5"; value = "5"; };
                                @{text = "6"; value = "6"; };
                                @{text = "7"; value = "7"; };
                                @{text = "8"; value = "8"; };
                                @{text = "9"; value = "9"; };
                                @{text = "10"; value = "10"; };
                            );
                            required = "true"; tabLabel = "l2q";
                        };
                    );
                    signHereTabs = @(
                        @{
                            anchorString = "/sn1/"; anchorUnits = "pixels";
                            anchorXOffset = "20"; anchorYOffset = "10";
                        };
                    );
                };
            };
        );
    };
    status       = "sent";
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
# ***DS.snippet.0.end

Write-Output ""
Write-Output "Results:"
Write-Output ""
Get-Content $response

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64

Write-Output ""
Write-Output "Done."
Write-Output ""

