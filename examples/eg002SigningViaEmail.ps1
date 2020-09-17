# Send an envelope with three documents

# If settings.txt file exist, we use all variables from this file
if (Test-Path .\config\settings.txt) {
    Get-Content ".\config\settings.txt" | Foreach-Object {
        $var = $_.Split('=')
        if ($var.Lengh -ne 2 -and $var[0].IsNullOrEmpty) {
            throw;
        }
        else {
            New-Variable -Name $var[0] -Value $var[1] -Force -Scope Global
        }
    }
}

# Get environment variables
$CC_EMAIL = $(Get-Variable CC_EMAIL -ValueOnly) -replace '["]'
$CC_NAME = $(Get-Variable CC_NAME -ValueOnly) -replace '["]'
$SIGNER_EMAIL = $(Get-Variable SIGNER_EMAIL -ValueOnly) -replace '["]'
$SIGNER_NAME = $(Get-Variable SIGNER_NAME -ValueOnly) -replace '["]'

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

# ***DS.snippet.0.start
#  document 1 (html) has tag **signature_1**
#  document 2 (docx) has tag /sn1/
#  document 3 (pdf) has tag /sn1/
#
#  The envelope has two recipients.
#  recipient 1 - signer
#  recipient 2 - cc
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.

$basePath = "https://demo.docusign.net/restapi"

# temp files:
$requestData = New-TemporaryFile
$requestDataTemp = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile
$doc2Base64 = New-TemporaryFile
$doc3Base64 = New-TemporaryFile

# Fetch docs and encode
$demoFile = $(Get-Location).Path + '\demo_documents\doc_1.html'
[Convert]::ToBase64String([IO.File]::ReadAllBytes($demoFile)) > $doc1Base64

$demoFile = $(Get-Location).Path + '\demo_documents\World_Wide_Corp_Battle_Plan_Trafalgar.docx'
[Convert]::ToBase64String([IO.File]::ReadAllBytes($demoFile)) > $doc2Base64

$demoFile = $(Get-Location).Path + '\demo_documents\World_Wide_Corp_lorem.pdf'
[Convert]::ToBase64String([IO.File]::ReadAllBytes($demoFile)) > $doc3Base64

Write-Output "`nSending the envelope request to DocuSign...`n"
Write-Output "The envelope has three documents. Processing time will be about 15 seconds.`n"
Write-Output "`nResults:`n"

# Concatenate the different parts of the request
Write-Output '{
    "emailSubject": "Please sign this document set",
    "documents": [
        {
            "documentBase64": "doc1Base64",
            "name": "Order acknowledgement",
            "fileExtension": "html",
            "documentId": "1"
        },
        {
            "documentBase64": "doc2Base64",
            "name": "Battle Plan",
            "fileExtension": "docx",
            "documentId": "2"
        },
        {
            "documentBase64": "doc3Base64",
            "name": "Lorem Ipsum",
            "fileExtension": "pdf",
            "documentId": "3"
        }
    ],
    "recipients": {
        "carbonCopies": [
            {
                "email": "CC_EMAIL",
                "name": "CC_NAME",
                "recipientId": "2",
                "routingOrder": "2"
            }
        ],
        "signers": [
            {
                "email": "SIGNER_EMAIL",
                "name": "SIGNER_EMAIL",
                "recipientId": "1",
                "routingOrder": "1",
                "tabs": {
                    "signHereTabs": [
                        {
                            "anchorString": "**signature_1**",
                            "anchorUnits": "pixels",
                            "anchorXOffset": "20",
                            "anchorYOffset": "10"
                        },
                        {
                            "anchorString": "/sn1/",
                            "anchorUnits": "pixels",
                            "anchorXOffset": "20",
                            "anchorYOffset": "10"
                        }
                    ]
                }
            }
        ]
    },
    "status": "sent"
}' >> $requestDataTemp

$((Get-Content -path $requestDataTemp -Raw) `
        -replace 'doc1Base64', $(Get-Content $doc1Base64) `
        -replace 'doc2Base64', $(Get-Content $doc2Base64) `
        -replace 'doc3Base64', $(Get-Content $doc3Base64) `
        -replace 'CC_EMAIL', $CC_EMAIL `
        -replace 'CC_NAME', $CC_NAME `
        -replace 'SIGNER_EMAIL', $SIGNER_EMAIL `
        -replace 'SIGNER_NAME', $SIGNER_NAME ) > $requestData

$headers = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type'  = 'application/json'
}

$parameters = @{
    Uri    = $basePath + "/v2.1/accounts/" + $accountId + "/envelopes"
    Method = 'POST'
    Infile = $requestData
}

try {
    Invoke-RestMethod -Headers $headers @parameters -OutFile $response
    Write-Output "Response: $(Get-Content -Raw $response)`n"
}
catch {
    Write-Error "Something went wrong " $_.Exception.Response.StatusCode
}

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId

# ***DS.snippet.0.end
# Save the envelope id for use by other scripts
Write-Output "EnvelopeId: $envelopeId"
Write-Output $envelopeId > .\config\ENVELOPE_ID

# cleanup
Remove-Item $requestData
Remove-Item $requestDataTemp
Remove-Item $response
Remove-Item $doc1Base64
Remove-Item $doc2Base64
Remove-Item $doc3Base64

Write-Output ""
Write-Output "Done."
Write-Output ""
