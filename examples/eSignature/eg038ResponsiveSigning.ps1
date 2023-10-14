$apiUri = "https://demo.docusign.net/restapi"

# Responsive signing

# Get required variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# 1. Obtain your OAuth token
$accessToken = Get-Content .\config\ds_access_token.txt

# Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountID = Get-Content .\config\API_ACCOUNT_ID

# Step 2. Create the envelope definition.
# The signer recipient includes a clientUserId setting
#
# The envelope will be sent first to the signer.
# After it is signed, a copy is sent to the cc person.

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc_html = New-TemporaryFile

# Fetch doc
[IO.File]::ReadAllText(".\demo_documents\order_form.html") > $doc_html

# Insert inner HTML

((Get-Content $doc_html) `
    -replace '/sn1/', '<ds-signature data-ds-role="Signer"/>' `
    -replace '/l1q/', '<input data-ds-type="number" name="l1q"/>' `
    -replace '/l2q/', '<input data-ds-type="number" name="l2q"/>') | Set-Content $doc_html

Write-Output "Sending the envelope request to DocuSign..."

$price1 = 5
$price2 = 150

# Concatenate the different parts of the request
#ds-snippet-start:eSign38Step2
@{
    emailSubject = "Example Signing Document";
    documents    = @(
        @{
            name           = "doc1.html";
            documentId     = "1";
            htmlDefinition = @{
                source = "$(Get-Content $doc_html)";
            };
        };
    );
    recipients = @{
        signers = @(
            @{
                email        = $variables.SIGNER_EMAIL;
                name         = $variables.SIGNER_NAME;
                recipientId  = "1";
                routingOrder = "1";
                clientUserId = "1000";
                roleName     = "Signer";
                tabs = @{
                    formulaTabs = @(
                        @{
                            font               = "helvetica";
                            fontSize           = "size11";
                            fontColor          = "black";
                            anchorString       = "/l1e/";
                            anchorYOffset      = "-8";
                            anchorUnits        = "pixels";
                            anchorXOffset      = "105";
                            tabLabel           = "l1e";
                            formula            = "[l1q] * $price1";
                            roundDecimalPlaces = "0";
                            required           = "true";
                            locked             = "true";
                            disableAutoSize    = "false";
                        };
                        @{
                            font               = "helvetica";
                            fontSize           = "size11";
                            fontColor          = "black";
                            anchorString       = "/l2e/";
                            anchorYOffset      = "-8";
                            anchorUnits        = "pixels";
                            anchorXOffset      = "105";
                            tabLabel           = "l2e";
                            formula            = "[l2q] * $price2";
                            roundDecimalPlaces = "0";
                            required           = "true";
                            locked             = "true";
                            disableAutoSize    = "false";
                        };
                        @{
                            font               = "helvetica";
                            fontSize           = "size11";
                            fontColor          = "black";
                            anchorString       = "/l3t/";
                            anchorYOffset      = "-8";
                            anchorUnits        = "pixels";
                            anchorXOffset      = "105";
                            tabLabel           = "l3t";
                            formula            = "[l1e] + [l2e]";
                            roundDecimalPlaces = "0";
                            required           = "true";
                            locked             = "true";
                            disableAutoSize    = "false";
                            bold               = "true";
                        };
                    );
                };
            };
        );
        carbonCopies = @(
            @{
                email        = $variables.CC_EMAIL;
                name         = $variables.CC_NAME;
                recipientId  = "2";
                routingOrder = "2";
            };
        );
    };
    status       = "sent";
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:eSign38Step2

# Step 3. Call DocuSign to create the envelope
#ds-snippet-start:eSign38Step3
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response
#ds-snippet-end:eSign38Step3

Write-Output "Response: $(Get-Content -Raw $response)"

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
Write-Output "EnvelopeId: $envelopeId"

# Step 4. Create a recipient view definition
# The signer will directly open this link from the browser to sign.
#
# The returnUrl is normally your own web app. DocuSign will redirect
# the signer to returnUrl when the signing completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from DocuSign

Write-Output "Requesting the url for the embedded signing..."

$json = [ordered]@{
    'returnUrl'            = 'http://httpbin.org/get';
    'authenticationMethod' = 'none';
    'email'                = $variables.SIGNER_EMAIL;
    'userName'             = $variables.SIGNER_NAME;
    'clientUserId'         = 1000
} | ConvertTo-Json -Compress


# Step 5. Create the recipient view and begin the DocuSign signing
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/views/recipient" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -Body $json `
    -OutFile $response

Write-Output "Response: $(Get-Content -Raw $response)"
$signingUrl = $(Get-Content $response | ConvertFrom-Json).url

Write-Output "The embedded signing URL is $signingUrl"
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser..."

Start-Process $signingUrl

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc_html

Write-Output "Done."
