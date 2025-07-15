$apiUri = "https://api-d.docusign.com/v1"

# check that a workspace exists
$workspaceId = Get-Content .\config\WORKSPACE_ID
if ([string]::IsNullOrWhiteSpace($workspaceId)) {
    Write-Host "Please create a workspace before running this example"
    exit 0
}

# Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# temp files:
$requestData = New-TemporaryFile

#ds-snippet-start:Workspaces2Step2
$boundary = [System.Guid]::NewGuid().ToString()
$headers = @{
	'Authorization' = "Bearer $accessToken";
	'Content-Type'  = "multipart/form-data; boundary=${boundary}";
}
#ds-snippet-end:Workspaces2Step2

try {
    $filePath = Read-Host "Enter the path to the document you want to add to the workspace"
    if (-Not (Test-Path -Path $filePath -PathType Leaf)) {
        Write-Host "File does not exist: $filePath"
        exit 1
    }

    $docName = Read-Host "Enter the name for the document in the workspace"

    #ds-snippet-start:Workspaces2Step3
    $form = @{
        file = Get-Item $filePath   # The file to upload
        name = $docName             # The document name
    }
    #ds-snippet-end:Workspaces2Step3
    
    #ds-snippet-start:Workspaces2Step4
    $response = $(Invoke-WebRequest `
        -Uri "${apiUri}/accounts/${accountId}/workspaces/${workspaceId}/documents" `
        -Method 'POST' `
        -headers $headers `
        -Form $form)
    #ds-snippet-end:Workspaces2Step4
} catch {
    Write-Output "Failed to add document to workspace."
    Write-Output $_
    exit 0
}

Write-Output "Response: $response"

# pull out the documentId
$documentId = $($response.Content | ConvertFrom-Json).document_id

# Save the document id for use by other scripts
Write-Output "Document added! ID: $documentId"
Write-Output $documentId > .\config\DOCUMENT_ID

# cleanup
Remove-Item $requestData

Write-Output "Done."
