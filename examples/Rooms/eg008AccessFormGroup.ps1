# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
#ds-snippet-start:Rooms8Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Rooms8Step2

# Get form groups
#ds-snippet-start:Rooms8Step3
$base_path = "https://demo.rooms.docusign.com"
$formGroupsUri = "$base_path/restapi/v2/accounts/$APIAccountId/form_groups"

try {
  Write-Output "Retrieving form groups..."
  $response = Invoke-WebRequest -uri $formGroupsUri -headers $headers -method GET
  $formGroups = ($response.Content | ConvertFrom-Json).formGroups

  if (-not $formGroups) {
    Write-Output "No form groups found. Execute code example 7 - Create a form group..."
    exit 1
  }

  # Display the form groups
  Write-Host "Available form groups:"
  for ($i = 0; $i -lt $formGroups.Count; $i++) {
    Write-Host "$($i + 1): $($formGroups[$i].name) (ID: $($formGroups[$i].formGroupId))"
  }

  # Prompt the user to select a form group
  $selection = Read-Host "Enter the number of the form group you want to use"
  if (-not ($selection -as [int]) -or $selection -lt 1 -or $selection -gt $formGroups.Count) {
    Write-Output "Invalid selection. Please enter a number between 1 and $($formGroups.Count)."
    exit 1
  }

  # Get the selected form group
  $selectedFormGroup = $formGroups[$selection - 1]
  $formGroupID = $selectedFormGroup.formGroupId
  Write-Host "You selected: $($selectedFormGroup.name)"
}
catch {
  Write-Output "Unable to retrieve form groups."
  Write-Output "Error: $($_.Exception.Message)"
  exit 1
}
#ds-snippet-end:Rooms8Step3

# Get an office ID
#ds-snippet-start:Rooms8Step4
$officeUri = "$base_path/restapi/v2/accounts/$APIAccountId/offices"

try {
  Write-Output "Retrieving office ID..."
  $response = Invoke-WebRequest -uri $officeUri -headers $headers -method GET
  $officeSummaries = ($response.Content | ConvertFrom-Json).officeSummaries

  if (-not $officeSummaries) {
    Write-Output "No offices found."
    exit 1
  }

  $officeID = $officeSummaries[0].officeId
}
catch {
  Write-Output "Unable to retrieve an office ID."
  Write-Output "Error: $($_.Exception.Message)"
  exit 1
}
#ds-snippet-end:Rooms8Step4

# Call the Rooms API to grant office access to the selected form group
#ds-snippet-start:Rooms8Step5
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_groups/$formGroupID/grant_office_access/$officeID"

try {
  Write-Output "Response:"
  $response = Invoke-WebRequest -uri $uri -headers $headers -method POST -body $body
  $response.StatusCode
  if ($response.StatusCode -eq "204") {
    Write-Output "Form group has been assigned to office ID."
  }

  # check that we have got a 204 Status code response
  if ($response.StatusCode -ne "204" ) {
    Write-Output "Unable to assign the provided form group ID to the provided office ID!"
    exit 1
  }
}
catch {
  Write-Output "Unable to grant office access to a form group"
  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
}
#ds-snippet-end:Rooms8Step5
