$apiUri = "https://api-d.docusign.com/v1"

# Check that a workspace exists
$workspaceId = Get-Content .\config\WORKSPACE_ID
if ([string]::IsNullOrWhiteSpace($workspaceId)) {
    Write-Host "Please create a workspace before running this example"
    exit 0
}

# Check that a workspace creator ID exists
$workspaceCreatorId = Get-Content .\config\WORKSPACE_CREATOR_ID
if ([string]::IsNullOrWhiteSpace($workspaceCreatorId)) {
    Write-Host "No creator ID was recorded. Please run the Create Workspace example before running this code"
    exit 0
}

# Get required variables from .\config\settings.json:
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Calculate ISO 8601 date 7 days from now (UTC)
$dueDate = (Get-Date).ToUniversalTime().AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")

#ds-snippet-start:Workspaces5Step2
$headers = @{
    'Authorization' = "Bearer $accessToken";
    'Accept'        = 'application/json';
    'Content-Type'  = 'application/json';
}
#ds-snippet-end:Workspaces5Step2

try {
    # Create the workspace definition
    #ds-snippet-start:Workspaces5Step3
    $body = @{
        name        = "Upload Request example $dueDate";
        description = 'This is an example upload request created via the workspaces API';
        status      = 'draft';
        due_date    = $dueDate;
        assignments = @(
            @{
                upload_request_responsibility_type_id = 'assignee';
                first_name                            = 'Test';
                last_name                             = 'User';
                email                                 = $variables.SIGNER_EMAIL;
            };
            @{
                assignee_user_id                      = "$workspaceCreatorId";
                upload_request_responsibility_type_id = 'watcher';
            };
        );
    } | ConvertTo-Json
    #ds-snippet-end:Workspaces5Step3

    #ds-snippet-start:Workspaces5Step4
    $response = $(Invoke-WebRequest `
        -Uri "${apiUri}/accounts/${accountId}/workspaces/${workspaceId}/upload-requests" `
        -Method 'POST' `
        -headers $headers `
        -body $body)
    #ds-snippet-end:Workspaces5Step4
} catch {
    Write-Output "Failed to create Workspace upload request."
    Write-Output $_
    exit 0
}

Write-Output "Response: $response"

# pull out the workspaceId
$uploadRequestId  = $($response.Content  | ConvertFrom-Json).upload_request_id 

Write-Output "Workspace upload request created! ID: $uploadRequestId"

Write-Output "Done."
