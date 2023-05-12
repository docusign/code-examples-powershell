# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Check that we have a clickwrap ID
if (Test-Path .\config\CLICKWRAP_ID) {
  $ClickWrapId = Get-Content .\config\CLICKWRAP_ID
}
else {
  Write-Output "Clickwrap ID required. Please run code example 1 - Create Clickwrap"
  exit 1
}

# Construct your API headers
#ds-snippet-start:Click6Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Click6Step2

$client_user_id = Read-Host "Please input a Client User Id (your own unique identifier) for the clickwrap"
$full_name = Read-Host "Please input a full name"
$email_address = Read-Host "Please input an email address"
$company_name = Read-Host "Please input a company name"
$title = Read-Host "Please input a job title"

# Construct the request body
#ds-snippet-start:Click6Step3
$requestData = New-TemporaryFile
$response = New-TemporaryFile

@{  
  clientUserId = $client_user_id;
  documentData = 
  @{
    fullName = $full_name;
    email    = $email_address;
    company  = $company_name;
    title    = $title;
    date     = $((Get-Date).ToString("yyyy-MM-ddThh:mm:ssK"))
  };
}  | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:Click6Step3

# Call the Click API
# a) Make a GET call to the users endpoint to retrieve responses (acceptance) of a specific clickwrap for an account
# b) Display the returned JSON structure of the responses
try {


  #ds-snippet-start:Click6Step4
  Invoke-RestMethod `
  -Uri "https://demo.docusign.net/clickapi/v1/accounts/$APIAccountId/clickwraps/$ClickWrapId/agreements" `
  -UseBasicParsing `
  -Method "POST" `
  -Headers @{
  "Authorization" = "Bearer $accessToken"
  "Content-Type"  = "application/json"
  "Accept" = "application/json"
} `
-InFile (Resolve-Path $requestData).Path `
-OutFile $response
#ds-snippet-end:Click6Step4

Write-Output "Response: $(Get-Content -Raw $response)"


# cleanup
Remove-Item $requestData
Remove-Item $response
Write-Output "Done."

}
catch {
  $errorMessage = $_.ErrorDetails.Message
  Write-Host ""
  if($errorMessage){
  if ( $errorMessage.Contains("There are no active versions for clickwrapId") ) {
      Write-Host "Clickwrap must be activated. Please run code example 2 - Activate Clickwrap"
  }
  elseif ( $errorMessage.Contains("Unable to find Clickwrap with id") ) {
    Write-Host "Clickwrap ID required. Please run code example 1 - Create Clickwrap"
  }

}
}
