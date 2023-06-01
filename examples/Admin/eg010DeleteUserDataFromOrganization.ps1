$accessToken = Get-Content .\config\ds_access_token.txt

$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$basePath = "https://api-d.docusign.net/management"
$organizationId=$variables.ORGANIZATION_ID

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")

# Get user information
$emailAddress = Read-Host "Please input the email address of the user whose data will be deleted. Note that this email address should be associated with a user that has been closed for at least 24 hours."

$uri = "${basePath}/v2.1/organizations/${organizationId}/users/dsprofile?email=${emailAddress}"
$response = Invoke-WebRequest -headers $headers -Uri $uri -body $body -Method GET

$userId = $($response.Content | ConvertFrom-Json).users.id
$accountId = $($response.Content | ConvertFrom-Json).users.memberships.account_id

# Construct the request body
$body = @"
  {
    "user_id": "$userId",
    "memberships": [{
      "account_id": "$accountId",
    }]
  }
"@

try {
  # Display the JSON response
  Write-Output ""
  Write-Output "Response:"
  $uri = "${basePath}/v2/data_redaction/organizations/${organizationId}/user"

	$result = Invoke-WebRequest -uri $uri -headers $headers -body $body -method POST
	$result.content
} catch {
  Write-Output "Unable to delete the user."

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
