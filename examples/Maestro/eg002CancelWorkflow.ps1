# Cancel a workflow instance

# Check that there is a workflow
if (-not (Test-Path .\config\WORKFLOW_ID)) {
  Write-Output "Please create a worklow before running this example"
  exit 0
}

# Check that there is a running workflow instance to cancel
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
#ds-snippet-start:Maestro2Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:Maestro2Step2

Write-Output "Attempting to cancel the Workflow Instance..."

#ds-snippet-start:Maestro2Step3
Invoke-RestMethod `
  -Uri "${base_path}/management/accounts/${accountId}/instances/${instanceId}/cancel" `
  -Method 'POST' `
  -Headers $headers `
  -OutFile $response

Write-Output "Workflow has been canceled."
Write-Output "Response: $(Get-Content -Raw $response)"
#ds-snippet-end:Maestro2Step3

# cleanup
Remove-Item $response

Write-Output "Done."
