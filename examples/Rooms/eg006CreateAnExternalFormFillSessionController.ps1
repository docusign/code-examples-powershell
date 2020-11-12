# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

# Get Room ID
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/rooms"
$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
$roomId = $($response.Content | ConvertFrom-Json).rooms[0].roomId

# Get Form Library ID
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/form_libraries"
$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers
$formLibraryId = $($response.Content | ConvertFrom-Json).formsLibrarySummaries.formsLibraryId

# Get Form ID
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/form_libraries/$formLibraryId/forms"
$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers
$formId = $($response.Content | ConvertFrom-Json).forms[0].libraryFormId

# Construct your request body
$body =
@"
{
  "roomId": $roomId,
  "formId": "$formId"
}
"@

# a) Call the v2 Rooms API
# b) Display the JSON response
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/external_form_fill_sessions"

try {
  Write-Output "Response:"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -body $body -method POST
  $response.Content | ConvertFrom-Json | ConvertTo-Json
}
catch {
  Write-Output "Unable to access form fill view link "
  # On failure, display a notification, X-DocuSign-TraceToken, error message,
  # and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
}