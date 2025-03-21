$apiUri = "https://demo.docusign.net/restapi"

# Redirect to the Docusign console web tool


# Step 1. Obtain your Oauth access token
$accessToken = Get-Content .\config\ds_access_token.txt
# Obtain your accountId from demo.docusign.net -- the account id is shown in
# the drop down on the upper right corner of the screen by your picture or
# the default picture.
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Check that we have an envelope id
if (-not (Test-Path .\config\ENVELOPE_ID)) {
    Write-Output "An envelope id is needed. Fix: execute script eg002SigningViaEmail.ps1"
    exit -1
}

# Check that we have an envelope id
$envelopeId = Get-Content .\config\ENVELOPE_ID

# The returnUrl is normally your own web app. Docusign will redirect
# the signer to returnUrl when the embedded signing completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from Docusign

# The web tool console can be opened in either of two views:
# The sending editor can be opened in either of two views:
Enum ViewType {
    FrontPage = 1;
    EnvelopeView = 2;
}

# The web tool console can be opened in either of two views:
$selectedView = $null;
do {
    Write-Output "Select the console view: "
    Write-Output "$([int][ViewType]::FrontPage) - Front page"
    Write-Output "$([int][ViewType]::EnvelopeView) - Envelope view"
    [int]$selectedView = Read-Host "Please make a selection"
} while (-not [ViewType]::IsDefined([ViewType], $selectedView));

Write-Output "Requesting the console view url"

#ds-snippet-start:eSign12Step2
$requestBody = switch ($selectedView) {
    { [ViewType]::FrontPage } {
        @{
            "returnUrl" = "http://httpbin.org/get"
        }; break;
    }
    { [ViewType]::EnvelopeView } {
        @{
            "returnUrl"  = "http://httpbin.org/get";
            "envelopeId" = "$envelopeId"
        }; break;
    }
    Default { }
}

$requestBody
$console = Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/views/console" `
    -Method "POST" `
    -Headers @{
    "Authorization" = "Bearer $accessToken";
    "Content-Type"  = "application/json";
} `
    -Body ($requestBody | ConvertTo-Json)

Write-Output "Results:"
Write-Output "Console received: $console"
$consoleUrl = $console.url
#ds-snippet-end:eSign12Step2

Write-Output "The console URL is $consoleUrl"
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser..."
Start-Process $consoleUrl

Write-Output "Done."
