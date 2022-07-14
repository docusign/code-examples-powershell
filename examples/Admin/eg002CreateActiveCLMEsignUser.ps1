# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Get required variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

$base_path = "https://api-d.docusign.net/management"
$organizationId=$variables.ORGANIZATION_ID

# Construct your API headers
# Step 2 start
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
# Step 2 end

# Step 3 Start
try {
  # Display the JSON response
  # Write-Output "Response:"
  $uri = "${base_path}/v2.1/organizations/${organizationId}/accounts/${APIAccountId}/products/permission_profiles"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
  # $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 4
  $productProfiles = $($response.Content | ConvertFrom-Json).product_permission_profiles
}
catch {
  Write-Output "Error:"
  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
  exit 1
}
# Step 3 end

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

if($null -eq $esignPermissionProfiles){
  Write-Output "You must create an eSignature permission profile before running this code example"
  exit 1
} elseif ($esignPermissionProfiles.count -eq 1){
  $esignPermissionProfileId = $esignPermissionProfiles[0].permission_profile_id
} else {
  $menu = @{}
  for ($i=1;$i -le $esignPermissionProfiles.count; $i++)
  { Write-Output "$i. $($esignPermissionProfiles[$i-1].permission_profile_name)"
  $menu.Add($i,($esignPermissionProfiles[$i-1].permission_profile_id))}
  do {
    [int]$selection = Read-Host 'Select an eSignature permission profile to assign to the new user'
  } while ($selection -gt $esignPermissionProfiles.count -or $selection -lt 1);
  $esignPermissionProfileId = $menu.Item($selection)
}

if($null -eq $clmPermissionProfiles){
  Write-Output "You must create a CLM permission profile before running this code example"
  exit 1
} elseif ($clmPermissionProfiles.count -eq 1){
  $clmPermissionProfileId = $clmPermissionProfiles[0].permission_profile_id
} else {
  $menu = @{}
  for ($i=1;$i -le $clmPermissionProfiles.count; $i++)
  { Write-Output "$i. $($clmPermissionProfiles[$i-1].permission_profile_name)"
  $menu.Add($i,($clmPermissionProfiles[$i-1].permission_profile_id))}
  do {
    [int]$selection = Read-Host 'Select a CLM permission profile to assign to the new user'
  } while ($selection -gt $clmPermissionProfiles.count -or $selection -lt 1);
  $clmPermissionProfileId = $menu.Item($selection)
}

# Step 4 Start
try {
  # Display the JSON response
  Write-Output "Response:"
  $uri = "${base_path}/v2.1/organizations/${organizationId}/accounts/${APIAccountId}/dsgroups"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET
  # $response.Content | ConvertFrom-Json | ConvertTo-Json
  $dsGroups = $($response.Content | ConvertFrom-Json).ds_groups
}
catch {
  Write-Output "Error:"
  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
  exit 1
}
# Step 4 end

if($dsGroups.count -eq 0){
  Write-Output "You must create a DS Group before running this code example"
  exit 1
} elseif ($dsGroups.count -eq 1){
  $dsGroupId = $dsGroups[0].ds_group_id
} else {
  $menu = @{}
  for ($i=1;$i -le $dsGroups.count; $i++)
  { Write-Output "$i. $($dsGroups[$i-1].group_name)"
  $menu.Add($i,($dsGroups[$i-1].ds_group_id))}
  do {
    [int]$selection = Read-Host 'Select a DS Group to assign the new user to'
  } while ($selection -gt $dsGroups.count -or $selection -lt 1);
  $dsGroupId = $menu.Item($selection)
}

$userName = Read-Host "Enter a username for the new user"
$firstName = Read-Host "Enter the first name of the new user"
$lastName = Read-Host "Enter the last name of the new user"
$userEmail = Read-Host "Enter an email for the new user"

# - Construct the request body for the new user
# Step 5 Start
$body = @"
{
  "user_name": "$userName",
  "first_name": "$firstName",
  "last_name": "$lastName",
  "email": "$userEmail",
  "auto_activate_memberships": true,
  "product_permission_profiles": [
      {
          "permission_profile_id": "$esignPermissionProfileId",
          "product_id": "$esignProductId"
      },
      {
          "permission_profile_id": "$clmPermissionProfileId",
          "product_id": "$clmProductId"
      }
  ],
  "ds_groups": [
      {
          "ds_group_id": "$dsGroupId"
      }
  ]
}
"@
# Step 5 end

# Step 6 Start
try {
  # Display the JSON response
  Write-Output "Response:"
  $uri = "${base_path}/v2.1/organizations/${organizationId}/accounts/${APIAccountId}/users/"
  $response = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -body $body -method POST
  $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5

  # Store user email to the file for future reference
  $($response.Content | ConvertFrom-Json).email > .\config\ESIGN_CLM_USER_EMAIL

  Write-Output "Done"
}
catch {
  Write-Output "Unable to create a new user."
  # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
  foreach ($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
  exit 1
}
# Step 6 end