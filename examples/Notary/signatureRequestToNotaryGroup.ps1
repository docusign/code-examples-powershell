$apiUri = "https://demo.docusign.net/restapi"

# Send an envelope with three documents

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Check that we have a Notary name and email in the settings.json config file
if ((!$variables.NOTARY_EMAIL) -or (!$variables.NOTARY_NAME) -or (!$variables.NOTARY_API_ACCOUNT_ID)) {
    Write-Output "NOTARY_EMAIL, NOTARY_NAME, and NOTARY_API_ACCOUNT_ID are needed. Please add the NOTARY_EMAIL, NOTARY_NAME, and NOTARY_API_ACCOUNT_ID variables to the settings.json"
    exit -1
}

# Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

#ds-snippet-start:Notary1Step2
$headers = @{
  'Authorization' = "Bearer $accessToken";
  'Accept'        = "application/json";
  'Content-Type'  = "application/json";
}
#ds-snippet-end

#  document 1 (html) has tag **signature_1**
#  document 2 (docx) has tag /sn1/
#  document 3 (pdf) has tag /sn1/
#
#  The envelope has two recipients.
#  recipient 1 - signer
#  recipient 2 - cc
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.


# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$docBase64 = New-TemporaryFile

[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_Battle_Plan_Trafalgar.docx"))) > $docBase64

Write-Output "Sending the envelope request to DocuSign..."
Write-Output "The envelope has three documents. Processing time will be about 15 seconds."
Write-Output "Results:"

# Concatenate the different parts of the request

#ds-snippet-start:Notary1Step3
@{
   emailSubject = "Please sign this document set";
   documents    = @(
       @{
           documentBase64 = "$(Get-Content $docBase64)";
           name           = "Order acknowledgement";
           fileExtension  = "html";
           documentId     = "1";
       };
   );
   recipients   = @{
       notaries = @(
           @{
               email        = $variables.NOTARY_EMAIL;
               name         = $variables.NOTARY_NAME;
               recipientId  = "1";
               routingOrder = "1";
               tabs         = @{
                   notarySealTabs = @(
                       @{
                           xPosition = "150";
                           yPosition = "50";
                           documentId = "1";
                           pageNumber = "1";
                       };
                   );
                   signHereTabs = @(
                       @{
                           xPosition = "300";
                           yPosition = "150";
                           documentId = "1";
                           pageNumber = "1";
                       };
                   )
               };
               userId = $variables.NOTARY_API_ACCOUNT_ID;
               notaryType = "remote";
           };
       );
       signers      = @(
           @{
               clientUserId = "12345";
               email        = $variables.SIGNER_EMAIL;
               name         = $variables.SIGNER_NAME;
               recipientId  = "2";
               routingOrder = "1";
               notaryId = "1";
               tabs         = @{
                   signHereTabs = @(
                       @{
                           documentId  = "1";
                           xPosition = "50";
                           yPosition = "50";
                           pageNumber = "1";
                       };
                       @{
                           stampType  = "stamp";
                           documentId = "1";
                           xPosition   = "200";
                           yPosition = "150";
                           pageNumber = "1";
                       };
                   );
               };
           };
       );
   };
   status       = "sent";
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end

# Create and send the envelope
#ds-snippet-start:Notary1Step4
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers $headers `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response

Write-Output "Response: $(Get-Content -Raw $response)"
#ds-snippet-end
# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId

# Save the envelope id for use by other scripts
Write-Output "EnvelopeId: $envelopeId"
Write-Output $envelopeId > .\config\ENVELOPE_ID

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $docBase64

Write-Output "Done."
