# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
#ds-snippet-start:Rooms6Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Rooms6Step2

# Get Room ID
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/rooms"
$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
$roomId = $($response.Content | ConvertFrom-Json).rooms[0].roomId

# Get Form Library ID
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/form_libraries"
$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers
$formLibraryId = $($response.Content | ConvertFrom-Json).formsLibrarySummaries[0].formsLibraryId

# Get Form ID
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/form_libraries/$formLibraryId/forms"
$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
$formId = $($response.Content | ConvertFrom-Json).forms[0].libraryFormId


# Construct your request body
#ds-snippet-start:Rooms6Step3
$body =
@"
{
  "roomId": "$roomId",
  "formId": "$formId",
  "xFrameAllowedUrl": "https://iframetester.com/"
}
"@
#ds-snippet-end:Rooms6Step3

# a) Call the v2 Rooms API
# b) Display the JSON response
#ds-snippet-start:Rooms6Step4
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/external_form_fill_sessions"

try {
  Write-Output "Response:"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -body $body -method POST
  $response.Content | ConvertFrom-Json | ConvertTo-Json
#ds-snippet-end:Rooms6Step4

#ds-snippet-start:Rooms6Step5
  $signingUrl = $($response.Content | ConvertFrom-Json).url

  $redirectUrl = "https://iframetester.com/?url="+$signingUrl

  Write-Output "The embedded form URL is $redirectUrl"
  Write-Output "Attempting to automatically open your browser..."

  Start-Process $redirectUrl
#ds-snippet-end:Rooms6Step5
}
catch {
  Write-Output "Unable to access form fill view link "
  # On failure, display a notification, X-DocuSign-TraceToken, error message,
  # and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }

  $errorMessage = $_.ErrorDetails.Message
  
  if ( $errorMessage.Contains("INVALID_REQUEST_PARAMETERS") ) { Write-Output "Problem: Create a room using example 1." }

  if ( $errorMessage.Contains("PROPERTY_VALIDATION_FAILURE") -or $errorMessage.Contains("FORM_NOT_IN_ROOM")) { Write-Output "Problem: Selected room does not have any forms. Add a form to a room using example 4." }
  
  Write-Output "Error : "$errorMessage
  Write-Output "Command : "$_.InvocationInfo.Line
  
}
