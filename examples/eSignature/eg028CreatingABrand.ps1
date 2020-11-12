# https://developers.docusign.com/docs/esign-rest-api/how-to/create-brand/

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$oAuthAccessToken = Get-Content .\config\ds_access_token.txt

#Set up variables for full code example
# Note: Substitute these values with your own
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

$brandName = Read-Host "Please enter a NEW brand name"

# Construct the request body
$body = @"
{
    "brandName": "${brandName}",
    "defaultBrandLanguage": "en"
}
"@

# a) Call the eSignature API
# b) Display the JSON response
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/brands"

try {
  Write-Output "Response:"
  $response = Invoke-WebRequest -uri $uri -headers $headers -body $body -method POST
  $($response.Content | ConvertFrom-Json).brands.brandId > .\config\BRAND_ID
  $response.Content | ConvertFrom-Json | ConvertTo-Json
}
catch {
  Write-Output "Unable to create a new brand."
  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
}