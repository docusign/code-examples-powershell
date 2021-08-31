# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
# Step 2 start
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
# Step 2 end

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Check that we have an organization id in the settings.json config file
if (!$variables.ORGANIZATION_ID) {
    Write-Output "Organization ID is needed. Please add the ORGANIZATION_ID variable to the settings.json"
    exit -1
}

$base_path = "https://api-d.docusign.net/management"
$organizationId = $variables.ORGANIZATION_ID

# Get groups and permission profile IDs

$uri = "${base_path}/v2/organizations/${organizationId}/accounts/${accountId}/permissions"
$result = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET

$permissionsObj = $($result.Content  | ConvertFrom-Json).permissions

# Setup a temporary menu option to pick a permission profile
$menu = @{}
  for ($i=1;$i -le $permissionsObj.count; $i++)
  { Write-Output "$i. $($permissionsObj[$i-1].name)"
  $menu.Add($i,($permissionsObj[$i-1].id))}
  do {
    [int]$selection = Read-Host 'Select an eSignature permission profile to assign to the new user'
  } while ($selection -gt $permissionsObj.count -or $selection -lt 1);
  $permissionsId = $menu.Item($selection)


$uri = "${base_path}/v2/organizations/${organizationId}/accounts/${accountId}/groups"
$result = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET

$groupsObj = $($result.Content  | ConvertFrom-Json).groups


# Setup a temporary menu option to pick a group
$menu = @{}
  for ($i=1;$i -le $groupsObj.count; $i++)
  { Write-Output "$i. $($groupsObj[$i-1].name)"
  $menu.Add($i,($groupsObj[$i-1].id))}
  do {
    [int]$selection = Read-Host 'Select an eSignature group Id to assign to the new user'
  } while ($selection -gt $groupsObj.count -or $selection -lt 1);
  $groupId = $menu.Item($selection)



$userName = Read-Host "Enter a username for the new user"
$firstName = Read-Host "Enter the first name of the new user"
$lastName = Read-Host "Enter the last name of the new user"
$userEmail = Read-Host "Enter an email for the new user"

# Construct the request body for the new user
# Step 3 start
$body = @"
{
  "user_name": "$userName",
  "first_name": "$firstName",
  "last_name": "$lastName",
  "email": "$userEmail",
  "auto_activate_memberships": true,
  "accounts": [
    {
      "id": "${accountId}",
      "permission_profile": {
        "id": $permissionsId,
      },
      "groups": [
        {
          "id": $groupId,
        }
      ]
    }
  ]
}
"@
# Step 3 end

$result = ""
# Call the DocuSign Admin API
# Step 4 start
$uri = "${base_path}/v2/organizations/${organizationId}/users"
$result = Invoke-WebRequest -headers $headers -Uri $uri -body $body -Method POST
$result.Content
# Step 4 end
