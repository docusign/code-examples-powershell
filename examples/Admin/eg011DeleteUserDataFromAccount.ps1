$accessToken = Get-Content .\config\ds_access_token.txt

$basePath = "https://api-d.docusign.net/management"
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")

# Get user information
$userId = Read-Host "Please enter the user ID of the user whose data will be deleted. Note that this user ID should be associated with a user that has been closed for at least 24 hours."

# Construct the request body
$body = @"
  {
    "user_id": "$userId",
  }
"@

try {
  # Display the JSON response
  Write-Output ""
  Write-Output "Response:"
  $uri = "${basePath}/v2/data_redaction/accounts/${APIAccountId}/user"

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
