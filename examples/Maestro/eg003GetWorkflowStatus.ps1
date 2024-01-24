# Get workflow instance state

# Check that there is a workflow
if (Test-Path .\config\WORKFLOW_ID) {
  $workflowId = Get-Content .\config\WORKFLOW_ID
} else {
  Write-Output "Please create a worklow before running this example"
  exit 0
}

# Check that there is an instance
if (Test-Path .\config\INSTANCE_ID) {
  $instanceId = Get-Content .\config\INSTANCE_ID
} else {
  Write-Output "Please trigger a workflow before running this example"
  exit 0
}

$base_path = "https://demo.services.docusign.net/aow-manage/v1.0"

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# temp file:
$response = New-TemporaryFile

# Construct your API headers
#ds-snippet-start:Maestro3Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:Maestro3Step2

Write-Output "Attempting to retrieve Workflow Instance Status..."

#ds-snippet-start:Maestro3Step3
Invoke-RestMethod `
  -Uri "${base_path}/management/accounts/${accountId}/workflowDefinitions/${workflowId}/instances/${instanceId}" `
  -Method 'GET' `
  -Headers $headers `
  -OutFile $response

$status = $(Get-Content $response | ConvertFrom-Json).instanceState

Write-Output "Workflow Status: $status"
Write-Output "Response: $(Get-Content -Raw $response)"
#ds-snippet-end:Maestro3Step3

# cleanup
Remove-Item $response

Write-Output "Done."
