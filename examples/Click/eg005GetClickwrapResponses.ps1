# Step 1. Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Check that we have a clickwrap ID
if (Test-Path .\config\CLICKWRAP_ID) {
    $ClickWrapId = Get-Content .\config\CLICKWRAP_ID
  }
  else {
    Write-Output "A clickwrap ID is needed. Fix: execute step 1 - Create clickwrap..."
    exit 1
}

# Step 2. Construct your API headers
#ds-snippet-start:Click5Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Click5Step2

# Step 3. Call the Click API
# a) Make a GET call to the users endpoint to retrieve responses (acceptance) of a specific clickwrap for an account
# b) Display the returned JSON structure of the responses
#ds-snippet-start:Click5Step3
$uri = "https://demo.docusign.net/clickapi/v1/accounts/$APIAccountId/clickwraps/$ClickWrapId/users"
$result = Invoke-WebRequest -headers $headers -Uri $uri -UseBasicParsing -Method GET
Write-Output "Response: "
$result.Content
#ds-snippet-end:Click5Step3