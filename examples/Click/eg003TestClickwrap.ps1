# Step 1. Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Step 2. Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

# Check that we have a Clickwrap ID
if (Test-Path .\config\CLICKWRAP_ID) {
    $ClickWrapId = Get-Content .\config\CLICKWRAP_ID
} else {
    Write-Output "PROBLEM: A Clickwrap ID is needed. Fix: execute step 1 - Create Clickwrap..."
    exit
}

# Check that the Clickwrap is activated
$uri = "https://demo.docusign.net/clickapi/v1/accounts/$APIAccountId/clickwraps/$ClickWrapId/"
$result = Invoke-WebRequest -headers $headers -Uri $uri -UseBasicParsing -Method GET
$clickwrapStatus = $($result.Content | ConvertFrom-Json).status

if ( $clickwrapStatus -ne "active") {
    Write-Output "PROBLEM: A Clickwrap ID is not active. Fix: execute step 2 - Activate Clickwrap..."
    exit 1
}

$environment = "demo"
$uri="https://developers.docusign.com/click-api/test-clickwrap?a=$APIAccountId&cw=$ClickWrapId&eh=$environment"

Write-Output "The clickwrap tester URL is $uri"
Write-Output ""

# Open the URI in a WebBrowser
Start-Process $uri