$apiUri = "https://demo.docusign.net/restapi"

# Download a document from an envelope
# This script uses the envelope_id stored in ../envelope_id.
# The envelope_id file is created by example eg002SigningViaEmail.ps1 or
# can be manually created.

# Configuration
# 1. Obtain an OAuth access token from
#    https://developers.docusign.com/oauth-token-generator
$accessToken = Get-Content .\config\ds_access_token.txt

# 2. Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

#
$outputFile = "envelope_document."

# Check that we have an envelope id
if (Test-Path .\config\ENVELOPE_ID) {
    $envelopeId = Get-Content .\config\ENVELOPE_ID
}
else {
    Write-Output "PROBLEM: An envelope id is needed. Fix: execute step 2 - Signing_Via_Email"
    exit 1
}

$docChoice = "1"
$outputFileExtension = "pdf"

Enum listDocs {
    Document1 = 1;
    Document2 = 2;
    Document3 = 3;
    CertificateOfCompletion = 4;
    DocumentsCombinedTogether = 5;
    ZIPfile = 6;
}

$listDocsView = $null;
do {
    Write-Output 'Select the initial sending view: '
    Write-Output "$([int][listDocs]::Document1) - Document 1"
    Write-Output "$([int][listDocs]::Document2) - Document 2"
    Write-Output "$([int][listDocs]::Document3) - Document 3"
    Write-Output "$([int][listDocs]::CertificateOfCompletion) - Certificate of Completion"
    Write-Output "$([int][listDocs]::DocumentsCombinedTogether) - Documents combined together"
    Write-Output "$([int][listDocs]::ZIPfile) - ZIP file"
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
else {
    $docChoice = $listDocsView
}

Write-Output "Sending the EnvelopeDocuments::get request to DocuSign..."
# ***DS.snippet.0.start
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/documents/${docChoice}" `
    -Method 'GET' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -OutFile ${outputFile}${outputFileExtension}
# ***DS.snippet.0.end
Write-Output "The document(s) are stored in file ${outputFile}${outputFileExtension}"
Write-Output "Done."