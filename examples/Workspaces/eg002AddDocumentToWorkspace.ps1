$apiUri = "https://api-d.docusign.com/v1"

# check that a workspace exists
$workspaceId = Get-Content .\config\WORKSPACE_ID
$workspaceName = Get-Content .\config\WORKSPACE_NAME
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

# Get the current script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Resolve the demo_documents directory (two levels up)
$DemoDocsPath = Resolve-Path (Join-Path $ScriptDir '..\..\demo_documents')

Write-Host ""
Write-Host "Enter the PDF file name (e.g. World_Wide_Corp_Web_Form.pdf) from the $DemoDocsPath folder:"
Write-Host ""

# Ask for the file until valid
while ($true) {
    $FileName = Read-Host
    $FilePath = Join-Path $DemoDocsPath $FileName

    if ($FileName -notmatch '\.pdf$') {
        Write-Host ""
        Write-Host "The file must be a PDF (must end with .pdf). Please try again."
        Write-Host ""
        continue
    }

    if (-not (Test-Path $FilePath)) {
        Write-Host ""
        Write-Host "File not found in demo_documents folder. Please try again."
        Write-Host ""
        continue
    }

    break
}

# Ask for document name to be used in the workspace
Write-Host ""
Write-Host "Enter the name for the document in the workspace (must end with .pdf):"
Write-Host ""

while ($true) {
    $DocName = Read-Host
    $DocName = $DocName.Trim()

    if ($DocName -match '\.pdf$') {
        break
    } else {
        Write-Host ""
        Write-Host "Invalid name. The document name must end with '.pdf' (e.g., example.pdf)."
        Write-Host "Please try again:"
        Write-Host ""
    }
}

try {
    #ds-snippet-start:Workspaces2Step3

    # Create a temporary copy with the desired document name
    $tempFilePath = Join-Path ([System.IO.Path]::GetTempPath()) $docName
    Copy-Item -Path $filePath -Destination $tempFilePath -Force

    $form = @{
        file = Get-Item $tempFilePath   # The file to upload (with the correct name)
        name = $docName                 # The document name
    }
    #ds-snippet-end:Workspaces2Step3

    Remove-Item $tempFilePath -Force
    
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
Write-Output "Document added to the workspace '$workspaceName'!! ID: $documentId"
Write-Output $documentId > .\config\DOCUMENT_ID

# cleanup
Remove-Item $requestData

Write-Output "Done."
