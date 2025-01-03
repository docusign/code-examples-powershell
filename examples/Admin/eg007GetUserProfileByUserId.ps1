# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt

# Construct your API headers
#ds-snippet-start:Admin7Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Admin7Step2

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Check that we have an organization id in the settings.json config file
if (!$variables.ORGANIZATION_ID) {
    Write-Output "Organization ID is needed. Please add the ORGANIZATION_ID variable to the settings.json"
    exit -1
}

$base_path = "https://api-d.docusign.net/management"
$organizationId = $variables.ORGANIZATION_ID

$userId = Read-Host "Enter the user's User ID"

$result = ""
# Call the Docusign Admin API
#ds-snippet-start:Admin7Step3
$uri = "${base_path}/v2.1/organizations/${organizationId}/users/${userId}/dsprofile"
$result = Invoke-WebRequest -headers $headers -Uri $uri -body $body -Method GET
$result.Content
#ds-snippet-end:Admin7Step3
