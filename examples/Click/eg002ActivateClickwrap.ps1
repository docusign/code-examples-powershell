# Step 1. Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID
$ClickWrapId = Get-Content .\config\CLICKWRAP_ID

# Step 2. Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

# Note: These values are not valid, but are shown for example purposes only!
$VersionNumber = "1"

# Construct your clickwrap JSON body
$body = @"
{ 
"status" : "active" 
}
"@

# a) Make a POST call to the clickwraps endpoint to activate the clickwrap for an account
# b) Display the JSON structure of the created clickwrap
$uri = "https://demo.docusign.net/clickapi/v1/accounts/$APIAccountId/clickwraps/$ClickWrapId/versions/$VersionNumber" 
$result = Invoke-WebRequest -headers $headers -Uri $uri -UseBasicParsing -Method PUT -Body $body
$result.Content
