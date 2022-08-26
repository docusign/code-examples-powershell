$apiUri = "https://demo.docusign.net/restapi"
$authorizationEndpoint = "https://account-d.docusign.com/oauth"

# Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Create the envelope definition.
#
#  document 1 (PDF) has tag /sn1/
#  recipient 1 - signer
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$docBase64 = New-TemporaryFile

# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $docBase64

$signerName = Read-Host "Please enter the name of the in person signer"

# Get the current user email
Invoke-RestMethod `
    -Uri "${authorizationEndpoint}/userinfo" `
    -Method 'GET' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Cache-Control'  = "no-store";
    'Pragma'  = "no-cache";
} `
    -OutFile $response

$hostEmail = $(Get-Content $response | ConvertFrom-Json).email
$hostName = $(Get-Content $response | ConvertFrom-Json).name

Write-Output "Sending the envelope request to DocuSign..."

# Concatenate the different parts of the request
# Step 2 start
@{
    emailSubject = "Please sign this document set";
    documents    = @(
        @{
            documentBase64 = "$(Get-Content $docBase64)";
            name           = "Lorem Ipsum";
            fileExtension  = "pdf";
            documentId     = "1";
        };
    );
    recipients   = @{
        inPersonSigners = @(
            @{
                hostEmail    = $hostEmail;
                hostName     = $hostName;
                signerName   = $signerName;
                recipientId  = "1";
                routingOrder = "1";
                tabs         = @{
                    signHereTabs = @(
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
# Step 2 end

# Call DocuSign to create the envelope
# Step 3 start
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

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
Write-Output "EnvelopeId: $envelopeId"
# Step 3 end

# Create a recipient view definition
# The signer will directly open this link from the browser to sign.
#
# The returnUrl is normally your own web app. DocuSign will redirect
# the signer to returnUrl when the signing completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from DocuSign

Write-Output "Requesting the url for the embedded signing..."

# Step 4 start
$json = [ordered]@{
    'returnUrl'            = 'http://httpbin.org/get';
    'authenticationMethod' = 'none';
    'email'                = $hostEmail;
    'userName'             = $hostName;
} | ConvertTo-Json -Compress
# Step 4 end


# Create the recipient view and begin the DocuSign signing
# Step 5 start
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
# Step 5 end

Write-Output "The embedded signing URL is $signingUrl"
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser..."

Start-Process $signingUrl

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $docBase64

Write-Output "Done."
