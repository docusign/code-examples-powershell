$apiUri = "https://demo.docusign.net/restapi"

# Set Envelope Tab Data

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Step 2. Create your authorization headers
#ds-snippet-start:eSign16Step2
$headers = @{
  'Authorization' = "Bearer $accessToken";
  'Content-Type'  = "application/json";
}
#ds-snippet-end:eSign16Step2

# Tabs and custom fields shown in the request body in step 4
# Step 3. Construct the request body

# Temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile

Write-Output "Sending the envelope request to DocuSign..."

# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_salary.docx"))) > $doc1Base64


#ds-snippet-start:eSign16Step3
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
            numericalTabs = @(@{
              ValidationType = "Currency";
              XPosition = "210";
              YPosition = "235";
              Height = "20";
              Width = "70";
              PageNumber = "1";
              DocumentId = "1";
              MinNumericalValue = "0";
              MaxNumericalValue = "1000000";
              TabId = "salary";
              TabLabel = "Salary";
              NumericalValue = "123000";
              LocalPolicy = @{
                CultureName = "en-US";
                CurrencyCode = "usd";
                CurrencyPositiveFormat = "csym_1_comma_234_comma_567_period_89";
                CurrencyNegativeFormat = "minus_csym_1_comma_234_comma_567_period_89";
                UseLongCurrencyFormat = "true";
              };
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
            };);
        };
      }; );
  };
  status             = "Sent";
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:eSign16Step3

# Step 4. Call the eSignature REST API
#ds-snippet-start:eSign15Step4
Invoke-RestMethod `
  -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
  -Method 'POST' `
  -Headers @{
  'Authorization' = "Bearer $accessToken";
  'Content-Type'  = "application/json";
} `
  -InFile (Resolve-Path $requestData).Path `
  -OutFile $response
#ds-snippet-end:eSign16Step4

Write-Output "Response:"
Get-Content $response

# Pull out the envelope ID
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
Write-Output "EnvelopeId: $envelopeId"

# Save the envelope ID for use by other scripts
Write-Output $envelopeId > .\config\ENVELOPE_ID

# Step 6. Create a recipient view (an embedded signing view)
#         that the signer will directly open in their browser to sign
#
# The return URL is normally your own web app. DocuSign will redirect
# the signer to the return URL when the DocuSign signing completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from DocuSign

Write-Output "Requesting the url for the embedded signing..."

#ds-snippet-start:eSign16Step5
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
  -Headers $headers `
  -InFile (Resolve-Path $requestData).Path`
  -OutFile $response

Write-Output "Response:"
Get-Content $response
#ds-snippet-end:eSign16Step5

$signingUrl = $(Get-Content $response | ConvertFrom-Json).url

Write-Output "The embedded signing URL is $signingUrl"
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser..."
Start-Process $signingUrl

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64

Write-Output "Done."
