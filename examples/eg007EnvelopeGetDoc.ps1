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

$basePath = "https://demo.docusign.net/restapi"

# Check that we have an envelope id
if (Test-Path .\config\ENVELOPE_ID) {
    $envelopeId = Get-Content .\config\ENVELOPE_ID
}
else {
    Write-Output "`nPROBLEM: An envelope id is needed. Fix: execute step 2 - Signing_Via_Email`n"
    exit 1
}

$docChoice = "1"
$outputFileExtension = "pdf"


# Create a List with Documents
$listDocs = @(
    "Document 1",
    "Document 2",
    "Document 3",
    "Certificate of Completion",
    "Documents combined together",
    "ZIP file"
)

# Create a blank array to hold menu
$formattedListDocs = @()
# Even Odd Columns
for ($i = 0; $i -lt $listDocs.Count; $i += 1) {
    if ($null -ne $listDocs[$i + 1]) {
        $formattedListDocs += [PSCustomObject]@{
            Odd = "$($i+1)) $($listDocs[$i])";
        }
    }
    else {
        $formattedListDocs += [PSCustomObject]@{
            Odd  = "$($i+1)) $($listDocs[$i])";
            Even = ""
        }
    }
}

# Output menu
$formattedListDocs | Format-Table -HideTableHeaders

# Read method from console
$METHOD = Read-Host "Select a document or document set to download"
switch ($METHOD) {
    '1' {
        $docChoice = "1"
    } '2' {
        $docChoice = "2"
    } '3' {
        $docChoice = "3"
    } '4' {
        $docChoice = "certificate"
    } '5' {
        $docChoice = "combined"
    } '6' {
        $docChoice = "archive"
        $outputFileExtension = "zip"
    }
}

Write-Output ""
Write-Output "Sending the EnvelopeDocuments::get request to DocuSign..."
Write-Output ""

# ***DS.snippet.0.start
try {
    Invoke-RestMethod `
        -Uri "${basePath}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/documents/${docChoice}" `
        -Method 'GET' `
        -Headers @{
        'Authorization' = "Bearer $accessToken";
        'Content-Type'  = "application/json"; 
    } `
        -OutFile ${outputFile}${outputFileExtension}
}
catch {
    Write-Error $_
}
# ***DS.snippet.0.end

Write-Output ""
Write-Output "The document(s) are stored in file ${outputFile}${outputFileExtension}"
Write-Output ""
Write-Output "Done."
Write-Output ""
