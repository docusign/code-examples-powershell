# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
# - Construct your API headers

#ds-snippet-start:Rooms2Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Rooms2Step2

# - Retrieve rooms pre-requisite data
# - Obtain our RoleID and OfficeID
#ds-snippet-start:Rooms2Step3
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/roles"
$uriOfficeId = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/offices"

try {
  $response = Invoke-RestMethod -uri $uri -headers $headers -method GET
  $roles = $response.roles
  $roleId = $roles.Where({$_.name -eq "Default Admin"}).roleId
  $roomTemplateId = $response.roomTemplates.roomTemplateId
  Write-Output "roleID:" $roleId
  $response = Invoke-RestMethod -uri $uriOfficeId -headers $headers -method GET
  $officeId = $response.officeSummaries[0].officeId
}
catch {
  Write-Output "Unable to make RoomsAPI Call"
  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
}
#ds-snippet-end:Rooms2Step3

# - Retrieve a Rooms template ID
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/room_templates"

try {
  $response = Invoke-RestMethod -uri $uri -headers $headers -method GET
  $response.Content
  $roomTemplateId = $response.roomTemplates.roomTemplateId
  Write-Output "TemplateId:" $roomTemplateId
}
catch {
  Write-Output "Unable to retrieve templateIds for rooms."
  #On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
}

# Construct the JSON body for your room
#ds-snippet-start:Rooms2Step4
$body = @"
{
  "name": "Sample Rooms Creation from Template",
  "roleId": "$roleId",
  "officeId": "$officeId",
  "RoomTemplateId": "$roomTemplateId",
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
#ds-snippet-end:Rooms2Step4

# a) Call the Rooms API
# b) Display JSON response
#ds-snippet-start:Rooms2Step5
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/rooms"

try {
  Write-Output "Response:"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -body $body -method POST
  $response.Content | ConvertFrom-Json | ConvertTo-Json
}
catch {
  Write-Output "Unable to create a new room."
  #On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
}
#ds-snippet-end:Rooms2Step5
