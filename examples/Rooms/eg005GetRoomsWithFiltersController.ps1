# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
#ds-snippet-start:Rooms5Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Rooms5Step2

#ds-snippet-start:Rooms5Step3
# Set your filtering parameters
$past = (Get-Date (Get-Date).AddDays(-10) -Format "yyyy-MM-dd")
# Set the date 1 day forward to account for changes made today
$current = (Get-Date (Get-Date).AddDays(1) -Format "yyyy-MM-dd")
#ds-snippet-end:Rooms5Step3

# Call the v2 Rooms API
#ds-snippet-start:Rooms5Step4
$uri = "https://demo.rooms.docusign.com/restapi/v2/accounts/$APIAccountId/rooms?fieldDataChangedStartDate=$past&fieldDataChangedEndDate=$current"

try {
  Write-Output "Response:"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers
  $response.Content | ConvertFrom-Json | ConvertTo-Json
}
catch {
  Write-Output "Unable to retrieve filtered rooms:"
  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response }
    $int++
  }
  Write-Output "Error : "$_
  Write-Output "Command : "$_.InvocationInfo.Line
}
#ds-snippet-end:Rooms5Step4
