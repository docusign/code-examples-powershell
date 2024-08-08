# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Get required variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$base_path = "https://api-d.docusign.net/management"
$organizationId=$variables.ORGANIZATION_ID

# Construct your API headers
#ds-snippet-start:Admin13Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Admin13Step2

try {
  #ds-snippet-start:Admin13Step3
  $uri = "${base_path}/v2/organizations/${organizationId}/planItems"
  $response = Invoke-WebRequest -headers $headers -Uri $uri -Method GET

  Write-Output "Results from the GET request:"
  $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
  #ds-snippet-end:Admin13Step3
} catch {
  Write-Output "Error:"
  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
  exit 1
}

$responseJson = $response.Content | ConvertFrom-Json
$planId = $responseJson.plan_id
$subscriptionId = $responseJson.subscription_id

$emailAddress = Read-Host "Please enter the email address for the new account"
$firstName = Read-Host "Please enter the first name for the new account"
$lastName = Read-Host "Please enter the last name for the new account"

#ds-snippet-start:Admin13Step4
# The country code value is set to "US" for the developer environment
# In production, set the value to the code for the country of the target account
$body = @"
{
  "subscriptionDetails": {
    "id": "$subscriptionId",
		"planId": "$planId",
		"modules": []
  },
  "targetAccount": {
    "name": "CreatedThroughAPI",
    "countryCode": "US",
    "admin": {
      "email": "$emailAddress",
      "firstName": "$firstName",
      "lastName": "$lastName",
      "locale": "en"
    }
  }
}
"@
#ds-snippet-end:Admin13Step4

try {
  #ds-snippet-start:Admin13Step5
  $uri = "${base_path}/v2/organizations/${organizationId}/assetGroups/accountCreate"
  $response = Invoke-WebRequest -headers $headers -Uri $uri -body $body -Method POST

  Write-Output "Results from the create account method:"
	$response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
  #ds-snippet-end:Admin13Step5
}
catch
{
  Write-Output "Error:"

  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") {
        Write-Output "TraceToken : " $_.Exception.Response.Headers[$int]
    }
    $int++
  }

  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
  exit 1
}

Write-Output ""
Write-Output "Done"
