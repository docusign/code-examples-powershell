$accessToken = Get-Content .\config\ds_access_token.txt

# Get required variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

$basePath = "https://api-d.docusign.net/management"
$organizationId=$variables.ORGANIZATION_ID

# Construct your API headers
#ds-snippet-start:Admin12Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:Admin12Step2

$response = $null

try {
  # Retrieve asset group accounts
  Write-Output ""
  Write-Output "Accounts to clone:"

  #ds-snippet-start:Admin12Step3
  $uri = "${basePath}/v1/organizations/${organizationId}/assetGroups/accounts?compliant=true"
	$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
  #ds-snippet-end:Admin12Step3
} catch {
  Write-Output "Unable retrieve asset group accounts."

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

$sourceAccountId = $null
$accounts = $($response.Content | ConvertFrom-Json).assetGroupAccounts
if ($accounts.count -eq 1){
  $sourceAccountId = $accounts[0].accountId
} else {
  $menu = @{}
  for ($i=1;$i -le $accounts.count; $i++)
  { Write-Output "$i. $($accounts[$i-1].accountName)"
  $menu.Add($i,($accounts[$i-1].accountId))}
  do {
    [int]$selection = Read-Host 'Select an account to clone'
  } while ($selection -gt $accounts.count -or $selection -lt 1);
  $sourceAccountId = $menu.Item($selection)
}

$targetAccountName = Read-Host "Please enter the name of the new account"
$targetAccountFirstName = Read-Host "Please enter the first name of the new account admin"
$targetAccountLastName = Read-Host "Please enter the last name of the new account admin"
$targetAccountEmail = Read-Host "Please enter the email address of the new account admin"

#ds-snippet-start:Admin12Step4
# The country code value is set to "US" for the developer environment
# In production, set the value to the code for the country of the target account
$body = @"
{
  "sourceAccount": {
    "id": "$sourceAccountId"
  },
  "targetAccount": {
    "name": "$targetAccountName",
    "admin": {
      "firstName": "$targetAccountFirstName",
      "lastName": "$targetAccountLastName",
      "email": "$targetAccountEmail"
    },
    "countryCode": "US"
  }
}
"@
#ds-snippet-end:Admin12Step4

try {
  # Clone source account into new account
  Write-Output ""
  Write-Output "Response:"

  #ds-snippet-start:Admin12Step5
  $uri = "${basePath}/v1/organizations/${organizationId}/assetGroups/accountClone"
	$response = Invoke-WebRequest -uri $uri -headers $headers -body $body -method POST
	$response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
  #ds-snippet-end:Admin12Step5
} catch {
  Write-Output "Failed to clone an account."

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
