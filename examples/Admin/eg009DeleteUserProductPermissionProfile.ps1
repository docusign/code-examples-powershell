# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID
$emailAddressFile = ".\config\ESIGN_CLM_USER_EMAIL"

# Get required variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$base_path = "https://api-d.docusign.net/management"
$organizationId=$variables.ORGANIZATION_ID

# Check that we have an email address of created user
if (Test-Path $emailAddressFile) {
  $emailAddress = Get-Content $emailAddressFile

  try {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.add("Authorization", "Bearer $accessToken")
    $headers.add("Content-Type", "application/json")

    $uri = "${base_path}/v2.1/organizations/${organizationId}/users/dsprofile?email=${emailAddress}"
    $response = Invoke-WebRequest -headers $headers -Uri $uri -body $body -Method GET
  } catch {
    Write-Output "The user with stored email address is not present in the account."
    Write-Output "Please run example 2: 'Create a new active CLM and eSignature user' before running this code example"
    exit 1
  }
} else {
  Write-Output "Please run example 2: 'Create a new active CLM and eSignature user' before running this code example"
  exit 1
}

# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

try {
  # Display the JSON response
  Write-Output "Getting permission profiles by email address..."
  $uri = "${base_path}/v2.1/organizations/${organizationId}/accounts/${APIAccountId}/products/permission_profiles/users?email=${emailAddress}"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
  $productProfiles = $($response.Content | ConvertFrom-Json).product_permission_profiles
  
  Write-Output "Response:"
  Write-Output ""
  Write-Output $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
  Write-Output ""
}
catch 
{
  Write-Output "Error:"

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

$clmProductId = "37f013eb-7012-4588-8028-357b39fdbd00"
$esignProductId = "f6406c68-225c-4e9b-9894-64152a26fa83"

Write-Output ""
Write-Output "Delete user product permission profile for the following email: " $emailAddress
Write-Output ""

Enum listProductChoices {
    CLM = 1;
    eSignature = 2;
}

$listProductChoicesView = $null;
do {
    Write-Output "$([int][listProductChoices]::CLM)) CLM"
    Write-Output "$([int][listProductChoices]::eSignature)) eSignature"
    [int]$listProductChoicesView = Read-Host "Which product permission profile would you like to delete?"
} while (-not [listProductChoices]::IsDefined([listProductChoices], $listProductChoicesView));

if ($listProductChoicesView -eq [listProductChoices]::CLM) {
    $productId = $clmProductId
} else {
    $productId = $esignProductId
}


foreach ($productProfile in $productProfiles) {
  if ($productProfile.product_id -eq $productId) {
    $userHasProductPermissions = "true"
  }
}

if ($null -eq $userHasProductPermissions) {
  Write-Output ""
  Write-Output "This user was already removed from this product."
  Write-Output "Please, try another product or run example 2: 'Create a new active CLM and eSignature user' to create a user with both product accesses."
  Write-Output ""
} else {
  # Construct the request body
  $body = @"
  {
      "user_email": "$emailAddress",
      "product_ids": [
        "$productId",
      ]
  }
"@

  try {
    # Display the JSON response
    Write-Output "Response:"
    $uri = "${base_path}/v2.1/organizations/${organizationId}/accounts/${APIAccountId}/products/users"
    Invoke-WebRequest -uri $uri -headers $headers -body $body -method DELETE
    
    Write-Output "Product permission profile has been deleted."
    Write-Output ""
    Write-Output "Done"
  } catch {
    Write-Output "Unable to delete the permission profile."

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
}
