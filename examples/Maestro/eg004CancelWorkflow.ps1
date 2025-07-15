# Cancel a workflow instance

# Check that there is a workflow
if (Test-Path .\config\WORKFLOW_ID) {
  $workflowId = Get-Content .\config\WORKFLOW_ID
} else {
  Write-Output "Please run example 1 to create and trigger a workflow before running this example,"
  exit 0
}

# Check that there is a running workflow instance to cancel
if (Test-Path .\config\INSTANCE_ID) {
  $workflowInstanceId = Get-Content .\config\INSTANCE_ID
} else {
  Write-Output "Please run example 1 to trigger a workflow before running this example."
  exit 0
}

$base_path = "https://api-d.docusign.com/v1"

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$apiAccountId = Get-Content .\config\API_ACCOUNT_ID

# temp file:
$response = New-TemporaryFile

# Construct your API headers
#ds-snippet-start:Maestro4Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:Maestro4Step2

Write-Output "Attempting to cancel the Workflow instance..."

#ds-snippet-start:Maestro4Step3
Invoke-RestMethod `
  -Uri "${base_path}/accounts/${apiAccountId}/workflows/${workflowId}/instances/${workflowInstanceId}/actions/cancel" `
  -Method 'POST' `
  -Headers $headers `
  -OutFile $response

#Write-Output "Workflow instance $workflowInstanceId has been canceled."
Write-Output "Response: $(Get-Content -Raw $response)"
#ds-snippet-end:Maestro4Step3

# cleanup
Remove-Item $response

Write-Output "Done."