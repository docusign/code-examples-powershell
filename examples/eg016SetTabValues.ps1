# Set Envelope Tab Data

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

$apiUri = "https://demo.docusign.net/restapi"

# Temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile

Write-Output ""
Write-Output "Sending the envelope request to DocuSign..."

# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_salary.docx"))) > $doc1Base64

# Step 2. Construct the JSON body for your envelope
@{
  customFields       = @{
    textCustomFields = @(@{
        name     = "salary";
        required = "false";
        show     = "true";
        value    = "123000";
      }; );
  };
  documents          = @(
    @{
      documentBase64 = "$(Get-Content $doc1Base64)";
      documentId     = "1";
      fileExtension  = "docx";
      name           = "Lorem Ipsum";
    };
  );
  emailBlurb         = "Sample text for email body";
  emailSubject       = "Please Sign";
  envelopeIdStamping = "true";
  recipients         = @{
    signers = @(@{
        clientUserId = "1000";
        email        = $variables.SIGNER_EMAIL;
        name         = $variables.SIGNER_NAME;
        recipientId  = "1";
        routingOrder = "1";
        tabs         = @{
          signHereTabs = @(@{
              anchorString  = "/sn1/";
              anchorUnits   = "pixels";
              anchorXOffset = "20";
              anchorYOffset = "10";
            }; );
          textTabs     = @(@{
              anchorString  = "/legal/";
              anchorUnits   = "pixels";
              anchorXOffset = "5";
              anchorYOffset = "-9";
              bold          = "true";
              font          = "helvetica";
              fontSize      = "size11";
              locked        = "false";
              tabId         = "legal_name";
              tabLabel      = "Legal name";
              value         = $variables.SIGNER_NAME;
            }; @{
              anchorString  = "/familiar/";
              anchorUnits   = "pixels";
              anchorXOffset = "5";
              anchorYOffset = "-9";
              bold          = "true";
              font          = "helvetica";
              fontSize      = "size11";
              locked        = "false";
              tabId         = "familiar_name";
              tabLabel      = "Familiar name";
              value         = $variables.SIGNER_NAME;
            }; @{
              anchorString  = "/salary/";
              anchorUnits   = "pixels";
              anchorXOffset = "5";
              anchorYOffset = "-9";
              bold          = "true";
              font          = "helvetica";
              fontSize      = "size11";
              locked        = "true";
              tabId         = "salary";
              tabLabel      = "Salary";
              value         = "$123,000.00";
            }; );
        };
      }; );
  };
  status             = "Sent";
} | ConvertTo-Json -Depth 32 > $requestData

# Step 3: a) Create your authorization headers
#         b) Send a POST request to the Envelopes endpoint
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
Write-Output "Response:"
Get-Content $response
Write-Output ""

# Pull out the envelope ID
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
Write-Output "EnvelopeId: $envelopeId"
Write-Output ""

# Save the envelope ID for use by other scripts
Write-Output $envelopeId > .\config\ENVELOPE_ID

# Step 4. Create a recipient view (a signing ceremony view)
#         that the signer will directly open in their browser to sign
#
# The return URL is normally your own web app. DocuSign will redirect
# the signer to the return URL when the signing ceremony completes.
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


Write-Output ""
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