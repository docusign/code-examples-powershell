# Resume creation of a workflow instance

# Check for workflow_id file existence and content
if (Test-Path "config/WORKFLOW_ID") {
    $workflowId = Get-Content "config/WORKFLOW_ID"
    if ([string]::IsNullOrWhiteSpace($workflowId)) {
        Write-Host "Workflow ID file is empty. Please run example 1 to create a workflow before running this example."
        exit 0
    }
} else {
    Write-Host "Workflow ID file does not exist. Please run example 1 to create a workflow before running this example."
    exit 1
}

# Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID
$basePath = "https://api-d.docusign.com/v1"

# Construct your API headers
#ds-snippet-start:Maestro3Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:Maestro3Step2

Write-Host ""
Write-Host "Attempting to resume the Workflow..."
Write-Host ""

# Make the API call to resume
$response = New-TemporaryFile
try {
#ds-snippet-start:Maestro3Step3
    Invoke-RestMethod `
      -Uri "${basePath}/accounts/${accountId}/workflows/${workflowId}/actions/resume" `
      -Method 'POST' `
      -Headers $headers `
      -OutFile $response
#ds-snippet-end:Maestro3Step3

    Write-Host ""
    Write-Host "Workflow has been resumed."
    Write-Host ""
    Write-Output "Response: $(Get-Content -Raw $response)"
} catch {
    Write-Output "Unable to resume creation of workflow instances."
    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") {
            Write-Output "TraceToken : " $_.Exception.Response.Headers[$int]
        }
        $int++
    }
    Write-Output "Error : " $_.ErrorDetails.Message
    Write-Output "Command : " $_.InvocationInfo.Line
}
Write-Host ""
