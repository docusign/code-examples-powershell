# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

# Get Role ID
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/roles"
$response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
$roleId = $($response.Content | ConvertFrom-Json).roles[0].roleid

# - Construct the request body for your room
$body = @"
{
  "name": "Sample Room Creation",
  "roleId": "$roleId",
  "transactionSideId": "listbuy",
  "fieldData": {
    "data" : {
     "address1": "123 EZ Street",
     "address2": "unit 10",
     "city": "Galaxian",
     "state": "US-HI",
     "postalCode": "11112",
     "companyRoomStatus": "5",
     "comments": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
      }
     }
}
"@

# a) Call the Rooms API
# b) Display the JSON response
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/rooms"

try {
  # Display the JSON response
  Write-Output "Response:"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -body $body -method POST
  $response.Content | ConvertFrom-Json | ConvertTo-Json
  $($response.Content | ConvertFrom-Json).roomId > .\config\ROOM_ID
}
catch {
  Write-Output "Unable to create a new room."
  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
}