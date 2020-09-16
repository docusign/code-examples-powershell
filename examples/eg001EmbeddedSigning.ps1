# Embedded signing ceremony

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
$accountID = Get-Content .\config\API_ACCOUNT_ID

# ***DS.snippet.0.start
# Step 1. Create the envelope.
#         The signer recipient includes a clientUserId setting
#
#  document 1 (pdf) has tag /sn1/
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

# Fetch doc and encode
$demoFile = $(Get-Location).Path + '\demo_documents\World_Wide_Corp_lorem.pdf'
[Convert]::ToBase64String([IO.File]::ReadAllBytes($demoFile)) > $doc1Base64

Write-Output "`nSending the envelope request to DocuSign...`n"

# Concatenate the different parts of the request
Write-Output '{
    "emailSubject": "Please sign this document set",
    "documents": [
        {
            "documentBase64": "doc1Base64",
            "name": "Lorem Ipsum",
            "fileExtension": "pdf",
            "documentId": "1"
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
                "name": "SIGNER_NAME",
                "recipientId": "1",
                "routingOrder": "1",
                "clientUserId": "1000",
                "tabs": {
                    "signHereTabs": [
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
}' > $requestDataTemp

$((Get-Content -path $requestDataTemp -Raw) `
        -replace 'doc1Base64', $(Get-Content $doc1Base64) `
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
    Write-Error $_
}

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
Write-Output "EnvelopeId: $envelopeId"

# Step 2. Create a recipient view (a signing ceremony view)
#         that the signer will directly open in their browser to sign.
#
# The returnUrl is normally your own web app. DocuSign will redirect
# the signer to returnUrl when the signing ceremony completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from DocuSign

Write-Output "`nRequesting the url for the signing ceremony...`n"

$json = [ordered]@{
    'returnUrl'            = 'http://httpbin.org/get';
    'authenticationMethod' = 'none';
    'email'                = $SIGNER_EMAIL;
    'userName'             = $SIGNER_NAME;
    'clientUserId'         = 1000
} | ConvertTo-Json -Compress

$headers = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type'  = 'application/json'
}

$parameters = @{
    Uri    = $basePath + "/v2.1/accounts/" + $accountId + "/envelopes/" + $envelopeId + "/views/recipient"
    Method = 'POST'
    Body   = $json
}

try {
    Invoke-RestMethod -Headers $headers @parameters -OutFile $response
    Write-Output "Response: $(Get-Content -Raw $response)`n"
}
catch {
    Write-Error $_
}

$signingCeremonyUrl = $(Get-Content $response | ConvertFrom-Json).url

# ***DS.snippet.0.end
Write-Output "The signing ceremony URL is $signingCeremonyUrl"
Write-Output ""
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser...`n"

Start-Process $signingCeremonyUrl

# cleanup
Remove-Item $requestData
Remove-Item $requestDataTemp
Remove-Item $response
Remove-Item $doc1Base64

Write-Output ""
Write-Output "Done."
Write-Output ""