# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
#ds-snippet-start:Rooms4Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Rooms4Step2

# Get Room ID
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/rooms"
$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
$roomId = $($response.Content | ConvertFrom-Json).rooms[0].roomId

# Get Form Library ID
#ds-snippet-start:Rooms4Step3
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/form_libraries"
$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers
$formLibraryId = $($response.Content | ConvertFrom-Json).formsLibrarySummaries[0].formsLibraryId

# Get Form ID
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/form_libraries/$formLibraryId/forms"
$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
$formId = $($response.Content | ConvertFrom-Json).forms[0].libraryFormId

# Construct the request body for adding a form
$body = @"
{"formId":"$formId"}
"@
#ds-snippet-end:Rooms4Step3


# Call the Rooms API
#ds-snippet-start:Rooms4Step4
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/rooms/$roomId/forms"

try {
  # Display the JSON response
  Write-Output "Response:"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -body $body -method POST
  $response.Content | ConvertFrom-Json | ConvertTo-Json
}
catch {
  Write-Output "Unable to add the new form."
  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
}
#ds-snippet-end:Rooms4Step4
