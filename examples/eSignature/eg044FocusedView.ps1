$apiUri = "https://demo.docusign.net/restapi"
$configPath = ".\config\settings.json"
$tokenPath = ".\config\ds_access_token.txt"
$accountIdPath = ".\config\API_ACCOUNT_ID"

# Get required variables from .\config\settings.json file
$variables = Get-Content $configPath -Raw | ConvertFrom-Json

# 1. Obtain your OAuth token
$accessToken = Get-Content $tokenPath

# Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountID = Get-Content $accountIdPath

$signerCountryCode = ""
$signerPhoneNumber = ""

Write-Output ""
$signerCountryCode = Read-Host "Enter signer country code to enable optional phone authentication (press Enter to skip)"
$signerPhoneNumber = Read-Host "Enter signer phone number to enable optional phone authentication (press Enter to skip)"

$signerCountryCode = if ($null -eq $signerCountryCode) { "" } else { $signerCountryCode.Trim() }
$signerPhoneNumber = if ($null -eq $signerPhoneNumber) { "" } else { $signerPhoneNumber.Trim() }

$hasSignerCountryCode = -not [string]::IsNullOrWhiteSpace($signerCountryCode)
$hasSignerPhoneNumber = -not [string]::IsNullOrWhiteSpace($signerPhoneNumber)

if ($hasSignerPhoneNumber -and -not $hasSignerCountryCode) {
    throw "Country code is required when phone number is provided."
}

if ($hasSignerCountryCode -and -not $hasSignerPhoneNumber) {
    throw "Phone number is required when country code is provided."
}

$usePhoneAuthentication = $hasSignerPhoneNumber

if ($usePhoneAuthentication) {
    $signerCountryCode = $signerCountryCode.TrimStart('+')
    $signerPhoneNumber = ($signerPhoneNumber -replace '[\s\-\(\)]', '').TrimStart('+')

    if ($signerCountryCode -notmatch '^\d{1,4}$') {
        throw "Country code must contain 1 to 4 digits."
    }

    if ($signerPhoneNumber -notmatch '^\d{4,20}$') {
        throw "Phone number must contain 4 to 20 digits."
    }
}

# Step 2. Create the envelope definition.

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile

function Cleanup-TempFiles {
    param(
        [string[]]$Paths
    )

    foreach ($path in $Paths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path)) {
            Remove-Item $path -ErrorAction SilentlyContinue
        }
    }
}

function Write-ApiFailureAndExit {
    param(
        [string]$StepName,
        [object]$ErrorRecord,
        [string[]]$TempPaths
    )

    Write-Error "$StepName failed."

    if ($null -ne $ErrorRecord.Exception.Response) {
        Write-Error "HTTP status: $($ErrorRecord.Exception.Response.StatusCode.value__)"
    }

    if (-not [string]::IsNullOrWhiteSpace($ErrorRecord.ErrorDetails.Message)) {
        Write-Error "DocuSign error: $($ErrorRecord.ErrorDetails.Message)"
    } else {
        Write-Error "$($ErrorRecord.Exception.Message)"
    }

    Cleanup-TempFiles -Paths $TempPaths
    exit 1
}

$workflowId = $null

$docPath = ".\demo_documents\World_Wide_Corp_lorem.pdf"

# Check the folder structure to switch paths for Quick ACG
if ((Test-Path $docPath) -eq $false) {
    $docPath = "..\demo_documents\World_Wide_Corp_lorem.pdf"
}

# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path $docPath))) > $doc1Base64

if ($usePhoneAuthentication) {
    Write-Output ""
    Write-Output "Looking up Phone Authentication identity verification workflow..."

    $identityVerificationResponse = Invoke-RestMethod `
        -Uri "${apiUri}/v2.1/accounts/${accountId}/identity_verification" `
        -Method 'GET' `
        -Headers @{
        'Authorization' = "Bearer $accessToken";
        'Accept'        = "application/json";
    }

    $workflow = $identityVerificationResponse.identityVerification | Where-Object { $_.defaultName -eq "Phone Authentication" } | Select-Object -First 1
    $workflowId = $workflow.workflowId

    if ([string]::IsNullOrWhiteSpace($workflowId)) {
        throw "IDENTITY_WORKFLOW_INVALID_ID"
    }
}

Write-Output "Sending the envelope request to Docusign..."
Write-Output ""

# Concatenate the different parts of the request
#ds-snippet-start:eSign44Step2
$signer = @{
    email        = $variables.SIGNER_EMAIL;
    name         = $variables.SIGNER_NAME;
    recipientId  = "1";
    routingOrder = "1";
    clientUserId = "1000";
}

if ($usePhoneAuthentication) {
    $signer.identityVerification = @{
        workflowId               = $workflowId;
        steps                    = $null;
        inputOptions             = @(
            @{
                name            = "phone_number_list";
                valueType       = "PhoneNumberList";
                phoneNumberList = @(
                    @{
                        countryCode = $signerCountryCode;
                        number      = $signerPhoneNumber;
                    }
                );
            }
        );
        idCheckConfigurationName = "";
    }
}

@{
    emailSubject = "Please sign this document set";
    documents    = @(
        @{
            documentBase64 = "$(Get-Content $doc1Base64)";
            name           = "Lorem Ipsum";
            fileExtension  = "pdf";
            documentId     = "1";
        }
    );
    recipients   = @{
        signers = @(
            $signer
        );
    };
    status       = "sent";
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:eSign44Step2

# Step 3. Call Docusign to create the envelope
#ds-snippet-start:eSign44Step3
try {
    Invoke-RestMethod `
        -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
        -Method 'POST' `
        -Headers @{
        'Authorization' = "Bearer $accessToken";
        'Content-Type'  = "application/json";
    } `
        -InFile (Resolve-Path $requestData).Path `
        -OutFile $response `
        -ErrorAction Stop
} catch {
    Write-ApiFailureAndExit -StepName "Create envelope request" -ErrorRecord $_ -TempPaths @($requestData, $response, $doc1Base64)
}
#ds-snippet-end:eSign44Step3

Write-Output "Response: $(Get-Content -Raw $response)"
Write-Output ""

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
if ([string]::IsNullOrWhiteSpace($envelopeId)) {
    Write-Error "Create envelope request failed: envelopeId was not returned."
    Cleanup-TempFiles -Paths @($requestData, $response, $doc1Base64)
    exit 1
}

Write-Output "EnvelopeId: $envelopeId"
Write-Output ""

# Step 4. Create a recipient view definition
# The signer will directly open this link from the browser to sign.
#
# The returnUrl is normally your own web app. Docusign will redirect
# the signer to returnUrl when the signing completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from Docusign

#ds-snippet-start:eSign44Step4
Write-Output "Requesting the url for the embedded signing..."
Write-Output ""

$json = @{
    returnUrl = "http://httpbin.org/get"
    authenticationMethod = "none"
    email = $variables.SIGNER_EMAIL
    userName = $variables.SIGNER_NAME
    clientUserId = 1000
    frameAncestors = @("http://localhost:8080", "https://apps-d.docusign.com")
    messageOrigins = @("https://apps-d.docusign.com")
}

$jsonString = $json | ConvertTo-Json
#ds-snippet-end:eSign44Step4

# Step 5. Create the recipient view and begin the Docusign signing
#ds-snippet-start:eSign44Step5
try {
    Invoke-RestMethod `
        -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/views/recipient" `
        -Method 'POST' `
        -Headers @{
        'Authorization' = "Bearer $accessToken";
        'Content-Type'  = "application/json";
    } `
        -Body $jsonString `
        -OutFile $response `
        -ErrorAction Stop
} catch {
    Write-ApiFailureAndExit -StepName "Create recipient view request" -ErrorRecord $_ -TempPaths @($requestData, $response, $doc1Base64)
}

Write-Output "Response: $(Get-Content -Raw $response)"

$signingUrl = $(Get-Content $response | ConvertFrom-Json).url
if ([string]::IsNullOrWhiteSpace($signingUrl)) {
    Write-Error "Create recipient view request failed: signing URL was not returned."
    
    Remove-Item $requestData
    Remove-Item $response
    Remove-Item $doc1Base64
    exit 1
}
#ds-snippet-end:eSign44Step5

$shellExecutable = "pwsh"
if ($IsWindows) {
    $shellExecutable = "powershell.exe"
}

Start-Process -NoNewWindow -FilePath $shellExecutable -ArgumentList "-File .\utils\startServerForFocusedView.ps1 -signingURL $signingUrl"

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64

Write-Output ""
Write-Output "Done."