. "utils/invokeScript.ps1"

# Trigger a workflow
if (-not (Test-Path .\config\WORKFLOW_ID)) {
  # create workflow
  Invoke-Script -Command "`".\examples\Maestro\createWorkflowUtils.ps1`""
}

$workflowId = Get-Content .\config\WORKFLOW_ID

# check that create workflow script ran successfully
if (Test-Path .\config\WORKFLOW_ID) {
  $workflowId = Get-Content .\config\WORKFLOW_ID
} else {
  Write-Output "Please create a workflow before running this example"
  exit 1
}

$base_path = "https://demo.services.docusign.net/v1"

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# temp files:
$response = New-TemporaryFile

# Construct your API headers
#ds-snippet-start:Maestro1Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:Maestro1Step2

Write-Output "Attempting to retrieve the workflow definition..."

#ds-snippet-start:Maestro1Step3
Invoke-RestMethod `
  -Uri "${base_path}/accounts/${accountId}/workflows/${workflowId}/trigger-requirements" `
  -Method 'GET' `
  -Headers $headers `
  -OutFile $response

$jsonContent = Get-Content -Path $response -Raw | ConvertFrom-Json
$triggerUrl = $jsonContent.trigger_http_config.url
$triggerUrl = $triggerUrl -replace "\\u0026", "&"
#ds-snippet-end:Maestro1Step3

$instance_name = Read-Host "Please input a name for the workflow instance"
$signerName = Read-Host "Please input the full name for the signer participant"
$signerEmail = Read-Host "Please input an email for the signer participant"
$ccName = Read-Host "Please input the full name for the cc participant"
$ccEmail = Read-Host "Please input an email for the cc participant"

#ds-snippet-start:Maestro1Step4
$body = @"
{
  "instance_name": "$instance_name",
  "trigger_inputs": {
    "signerEmail": "$signerEmail",
    "signerName": "$signerName",
    "ccEmail": "$ccEmail",
    "ccName": "$ccName"
  }
}
"@
#ds-snippet-end:Maestro1Step4

if (-not ([string]::IsNullOrEmpty($triggerUrl))) {
  #ds-snippet-start:Maestro1Step5
  $triggerResult = Invoke-WebRequest -uri $triggerUrl -headers $headers -body $body -method POST -UseBasicParsing
  #ds-snippet-end:Maestro1Step5
  Write-Host $triggerResult
  Write-Host ""

  $workflowInstanceId = $($triggerResult | ConvertFrom-Json).instance_id
  $workflowInstanceId | Out-File -FilePath "config/INSTANCE_ID" -Encoding utf8 -Force
  Write-Host "Successfully created and published workflow $workflowInstanceId, ID saved to config/INSTANCE_ID"


  $instanceUrl = $($triggerResult | ConvertFrom-Json).instance_url
  # Decode escaped characters
  $instanceUrl = $instanceUrl -replace "\\u0026", "&"
  Write-Host "Use this URL to complete the workflow steps:"
  Write-Host $instanceUrl


  Write-Host ""
  Write-Host "Opening a browser with the embedded workflow..."

  # Wait a bit to let the server start
  Start-Sleep -Seconds 2

  # Start script for the embedded workflow
& "./examples/Maestro/startServerForEmbeddingWorkflow.ps1" -instanceUrl $instanceUrl

  # Open the browser
  Start-Process "http://localhost:8080"
} else {
  Write-Host ""
  Write-Host "The WORKFLOW_ID file contains the ID of the unpublished maestro workflow. Please, delete this file and try running the example again."
}