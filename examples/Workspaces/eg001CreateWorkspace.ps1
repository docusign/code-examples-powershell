$apiUri = "https://api-d.docusign.com/v1"

# Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

#ds-snippet-start:Workspaces1Step2
$headers = @{
    'Authorization' = "Bearer $accessToken";
    'Accept'        = 'application/json';
    'Content-Type'  = 'application/json';
}
#ds-snippet-end:Workspaces1Step2

try {
    # Create the workspace definition
    #ds-snippet-start:Workspaces1Step3
    $body = @{
        name = "Example workspace";
    } | ConvertTo-Json
    #ds-snippet-end:Workspaces1Step3

    #ds-snippet-start:Workspaces1Step4
    $response = $(Invoke-WebRequest `
        -Uri "${apiUri}/accounts/${accountId}/workspaces" `
        -Method 'POST' `
        -headers $headers `
        -body $body)
    #ds-snippet-end:Workspaces1Step4
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
Write-Output $workspaceId > .\config\WORKSPACE_ID

Write-Output "Done."
