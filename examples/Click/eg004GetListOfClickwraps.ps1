# Step 1. Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Step 2. Construct your API headers
#ds-snippet-start:Click4Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Click4Step2

# Step 3. Call the Click API
# a) Make a GET call to the clickwraps endpoint to retrieve all clickwraps for an account
# b) Display the JSON structure of the returned clickwraps
#ds-snippet-start:Click4Step3
$uri = "https://demo.docusign.net/clickapi/v1/accounts/$APIAccountId/clickwraps"
$result = Invoke-WebRequest -headers $headers -Uri $uri -UseBasicParsing -Method GET
Write-Output "Response: "
$result.Content
#ds-snippet-end:Click4Step3
