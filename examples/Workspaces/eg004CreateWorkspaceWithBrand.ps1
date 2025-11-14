. "utils/invokeScript.ps1"

#ds-snippet-start:Workspaces4Step2
# check that a brand exists
$path = ".\config\BRAND_ID"
if (-not (Test-Path $path) -or [string]::IsNullOrWhiteSpace((Get-Content $path))) {
    Write-Host "No brand_id found. Attempting to run eg028CreatingABrand.ps1..."
    Invoke-Script -Command "`"./examples/eSignature/eg028CreatingABrand.ps1`""
}

# re-check after attempt
$brandId = Get-Content .\config\BRAND_ID
if ([string]::IsNullOrWhiteSpace($brandId)) {
    Write-Host "Brand creation did not produce a brand_id. Please create a brand first."
    exit 1
}
#ds-snippet-end:Workspaces4Step2

$apiUri = "https://api-d.docusign.com/v1"

# Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

#ds-snippet-start:Workspaces4Step3
$headers = @{
    'Authorization' = "Bearer $accessToken";
    'Accept'        = 'application/json';
    'Content-Type'  = 'application/json';
}
#ds-snippet-end:Workspaces4Step3

try {
    # Create the workspace definition
    #ds-snippet-start:Workspaces4Step4
    $body = @{
        name     = "Example workspace";
        brand_id = "$brandId"
    } | ConvertTo-Json
    #ds-snippet-end:Workspaces4Step4

    #ds-snippet-start:Workspaces4Step5
    $response = $(Invoke-WebRequest `
        -Uri "${apiUri}/accounts/${accountId}/workspaces" `
        -Method 'POST' `
        -headers $headers `
        -body $body)
    #ds-snippet-end:Workspaces4Step5
} catch {
    Write-Output "Failed to create Workspace."
    Write-Output $_
    exit 0
}

Write-Output "Response: $response"

# pull out the workspaceId
$workspaceId = $($response.Content  | ConvertFrom-Json).workspace_id

# Save the envelope id for use by other scripts
Write-Output "Workspace created! ID: $workspaceId"
Write-Output "Brand used: $brandId"
Write-Output $workspaceId > .\config\WORKSPACE_ID

Write-Output "Done."
