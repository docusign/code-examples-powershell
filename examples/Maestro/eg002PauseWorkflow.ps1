# Pause a running workflow instance

# Check for workflow_id file existence and content
if (Test-Path "config/WORKFLOW_ID") {
    $workflowId = Get-Content "config/WORKFLOW_ID"
    if ([string]::IsNullOrWhiteSpace($workflowId)) {
        Write-Host "Workflow ID file is empty. Please run example 1 to create a workflow before running this example."
        exit 0
    }
} else {
    Write-Host "Workflow ID file does not exist.  Please run example 1 to create a workflow before running this example."
    exit 1
}
# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

$basePath = "https://api-d.docusign.com/v1"

# Construct your API headers
#ds-snippet-start:Maestro2Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:Maestro2Step2

Write-Host ""
Write-Host "Attempting to pause the Workflow.."
Write-Host ""

# Send the POST request

$response = New-TemporaryFile
try {
    #ds-snippet-start:Maestro2Step3
    Invoke-RestMethod `
      -Uri "${basePath}/accounts/${accountId}/workflows/${workflowId}/actions/pause" `
      -Method 'POST' `
      -Headers $headers `
      -OutFile $response
    #ds-snippet-end:Maestro2Step3

    Write-Host ""
    Write-Host "Workflow has been paused."
    Write-Host ""
    Write-Output "Response: $(Get-Content -Raw $response)"
} catch {
    Write-Output "Unable to pause creation of workflow instances."
    # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}
Write-Host ""

