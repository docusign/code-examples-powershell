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
#ds-snippet-start:Admin8Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Admin8Step2

try {
  # Get all permission profiles
  Write-Output "Getting permission profiles..."
  $uri = "${base_path}/v2.1/organizations/${organizationId}/accounts/${APIAccountId}/products/permission_profiles"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
  $productProfiles = $($response.Content | ConvertFrom-Json).product_permission_profiles

  # Get and showcase permission profiles that are currently added to the user
  $uri = "${base_path}/v2.1/organizations/${organizationId}/accounts/${APIAccountId}/products/permission_profiles/users?email=${emailAddress}"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
  
  Write-Output "Response:"
  Write-Output ""
  Write-Output $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
  Write-Output ""
}
catch {
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

$esignPermissionProfiles = $null
$clmPermissionProfiles = $null

foreach ($productProfile in $productProfiles) {
  if ($productProfile.product_name -eq "ESign") {
    $esignPermissionProfiles = $productProfile.permission_profiles
    $esignProductId = $productProfile.product_id
  } else {
    $clmPermissionProfiles = $productProfile.permission_profiles
    $clmProductId = $productProfile.product_id
  }
}

Write-Output ""
Write-Output "Update user product permission profile for the following email: $emailAddress"
Write-Output ""

Enum listProductChoices {
    CLM = 1;
    eSignature = 2;
}
$listProductChoicesView = $null;
do {
    Write-Output "$([int][listProductChoices]::CLM)) CLM"
    Write-Output "$([int][listProductChoices]::eSignature)) eSignature"
    [int]$listProductChoicesView = Read-Host "Would you like to update the permission profile for the eSignature or CLM product?"
} while (-not [listProductChoices]::IsDefined([listProductChoices], $listProductChoicesView));

if ($listProductChoicesView -eq [listProductChoices]::CLM) {
    $productId = $clmProductId
    Write-Output ""

    $menu = @{}
    for ($i=1;$i -le $clmPermissionProfiles.count; $i++) { 
        Write-Output "$i. $($clmPermissionProfiles[$i-1].permission_profile_name)"
        $menu.Add($i,($clmPermissionProfiles[$i-1].permission_profile_id))
    }

    do {
        [int]$selection = Read-Host 'Select a CLM permission profile to update'
    } while ($selection -gt $clmPermissionProfiles.count -or $selection -lt 1);
    
    $permissionProfileId = $menu.Item($selection)
} else {
    $productId = $esignProductId
    Write-Output ""

    $menu = @{}
    for ($i=1;$i -le $esignPermissionProfiles.count; $i++) { 
        Write-Output "$i. $($esignPermissionProfiles[$i-1].permission_profile_name)"
        $menu.Add($i,($esignPermissionProfiles[$i-1].permission_profile_id))
    }

    do {
        [int]$selection = Read-Host 'Select an eSignature permission profile to update'
    } while ($selection -gt $esignPermissionProfiles.count -or $selection -lt 1);
    
    $permissionProfileId = $menu.Item($selection)
}

# Construct the request body
#ds-snippet-start:Admin8Step3
$body = @"
{
    "email": "$emailAddress",
    "product_permission_profiles": [
        {
        "product_id": '$productId',
        "permission_profile_id": '$permissionProfileId',
        }
    ]
}
"@
#ds-snippet-end:Admin8Step3

try {
  # Display the JSON response
  Write-Output "Response:"
#ds-snippet-start:Admin8Step4
  $uri = "${base_path}/v2.1/organizations/${organizationId}/accounts/${APIAccountId}/products/permission_profiles/users"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -body $body -method POST
  $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 4
#ds-snippet-end:Admin8Step4
  
  Write-Output "Done"
}
catch {
  Write-Output "Unable to update the permission profiles."
  
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
