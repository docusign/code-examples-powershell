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
  Write-Output "Please create a worklow before running this example"
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

Write-Output "Attempting to retrieve Workflow definition..."

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
$signer_name = Read-Host "Please input the full name for the signer participant"
$signer_email = Read-Host "Please input an email for the signer participant"
$cc_name = Read-Host "Please input the full name for the cc participant"
$cc_email = Read-Host "Please input an email for the cc participant"

#ds-snippet-start:Maestro1Step4
$body = @"
{
  "instance_name": "$instance_name",
  "trigger_inputs": {
    "signer_email": "$signer_email",
    "signer_name": "$signer_name",
    "cc_email": "$cc_email",
    "cc_name": "$cc_name"
  }
}
"@
#ds-snippet-end:Maestro1Step4

#ds-snippet-start:Maestro1Step5
$triggerResult = Invoke-WebRequest -uri $triggerUrl -headers $headers -body $body -method POST
#ds-snippet-end:Maestro1Step5


$instanceUrl = $($triggerResult | ConvertFrom-Json).instance_url
$instanceUrl = $instanceUrl -replace "\\u0026", "&"
Write-Output "Response: $instanceUrl"

# pull out the envelopeId
$instanceId = $($triggerResult | ConvertFrom-Json).instance_id
# Store the instance_id into the config file
Write-Output $instanceId > .\config\INSTANCE_ID

# cleanup
Remove-Item $response

Write-Output "Done."