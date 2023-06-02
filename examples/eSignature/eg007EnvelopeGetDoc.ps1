$apiUri = "https://demo.docusign.net/restapi"

# Download a document from an envelope
# This script uses the envelope_id stored in ../envelope_id.
# The envelope_id file is created by example eg002SigningViaEmail.ps1 or
# can be manually created.


# Obtain your Oauth access token
$accessToken = Get-Content .\config\ds_access_token.txt

# Obtain your accountId from demo.docusign.net -- the account id is shown in
# the drop down on the upper right corner of the screen by your picture or
# the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

#
$outputFile = "envelope_document."

# Check that we have an envelope id
if (Test-Path .\config\ENVELOPE_ID) {
    $envelopeId = Get-Content .\config\ENVELOPE_ID
}
else {
    Write-Output "PROBLEM: An envelope id is needed. Fix: execute code example 2 - Signing_Via_Email"
    exit 1
}

#ds-snippet-start:eSign7Step2
$headers = @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
  }
#ds-snippet-end:eSign7Step2

$docChoice = "1"
$outputFileExtension = "pdf"

Enum listDocs {
    Document1 = 1;
    Document2 = 2;
    Document3 = 3;
    CertificateOfCompletion = 4;
    DocumentsCombinedTogether = 5;
    ZIPfile = 6;
    PDFPortfolio = 7;
}

$listDocsView = $null;
do {
    Write-Output 'Select a document or document set to download:'
    Write-Output "$([int][listDocs]::Document1) - Document 1"
    Write-Output "$([int][listDocs]::Document2) - Document 2"
    Write-Output "$([int][listDocs]::Document3) - Document 3"
    Write-Output "$([int][listDocs]::CertificateOfCompletion) - Certificate of Completion"
    Write-Output "$([int][listDocs]::DocumentsCombinedTogether) - Documents combined together"
    Write-Output "$([int][listDocs]::ZIPfile) - ZIP file"
    Write-Output "$([int][listDocs]::PDFPortfolio) - PDF Portfolio"
    [int]$listDocsView = Read-Host "Please make a selection"
} while (-not [listDocs]::IsDefined([listDocs], $listDocsView));



if ($listDocsView -eq [listDocs]::CertificateOfCompletion) {
    $docChoice = "certificate"
}
elseif ($listDocsView -eq [listDocs]::DocumentsCombinedTogether) {
    $docChoice = "combined"
}
elseif ($listDocsView -eq [listDocs]::ZIPfile) {
    $docChoice = "archive"
    $outputFileExtension = "zip"
}
elseif ($listDocsView -eq [listDocs]::PDFPortfolio) {
    $docChoice = "portfolio"
    $outputFileExtension = "pdf"
}
else {
    $docChoice = $listDocsView
}

Write-Output "Sending the EnvelopeDocuments::get request to DocuSign..."
# Call the eSignature API
#ds-snippet-start:eSign7Step3
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/documents/${docChoice}" `
    -Method 'GET' `
    -Headers $headers `
    -OutFile ${outputFile}${outputFileExtension}
#ds-snippet-end:eSign7Step3
Write-Output "The document(s) are stored in file ${outputFile}${outputFileExtension}"
Write-Output "Done."
