$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..") ).Path
$apiUri = "https://api-d.docusign.com/v1"
$configPath = Join-Path $projectRoot "config/settings.json"
$tokenPath = Join-Path $projectRoot "config/ds_access_token.txt"
$accountIdPath = Join-Path $projectRoot "config/API_ACCOUNT_ID"

# Get required variables from config and token files.
$config = Get-Content $configPath -Raw | ConvertFrom-Json
$accessToken = (Get-Content $tokenPath -Raw).Trim()
$accountId = (Get-Content $accountIdPath -Raw).Trim()

$demoFiles = @(
    (Join-Path $projectRoot "demo_documents/World_Wide_Corp_Battle_Plan_Trafalgar.docx"),
    (Join-Path $projectRoot "demo_documents/World_Wide_Corp_lorem.pdf"),
    (Join-Path $projectRoot "demo_documents/doc_1.html"),
    (Join-Path $projectRoot "demo_documents/Welcome.txt"),
    (Join-Path $projectRoot "demo_documents/Id.jpg")
)

$existingFiles = $demoFiles | Where-Object { Test-Path $_ }
if ($existingFiles.Count -eq 0) {
    Write-Output "No demo documents were found for upload."
    exit 0
}

$headers = @{
    Authorization = "Bearer $accessToken"
    Accept        = "application/json"
    "Content-Type" = "application/json"
}

$createBody = @{
    job_name                = "Example bulk upload job"
    expected_number_of_docs = $existingFiles.Count
    language                = "en-US"
} | ConvertTo-Json

$createResponse = Invoke-WebRequest `
    -Uri "$apiUri/accounts/$accountId/upload/jobs" `
    -Method POST `
    -Headers $headers `
    -Body $createBody

$createResponseText = $createResponse.Content
$createResponseJson = $createResponseText | ConvertFrom-Json
$jobId = $createResponseJson.id

$uploadUrlMatches = [regex]::Matches($createResponseText, '"upload_document"\s*:\s*"([^"]+)"')
$uploadUrls = @()
foreach ($match in $uploadUrlMatches) {
    $uploadUrls += ($match.Groups[1].Value -replace '\\/', '/')
}

if ([string]::IsNullOrWhiteSpace($jobId)) {
    Write-Output "Could not read the upload job id from the API response."
    Write-Output "Response: $createResponseText"
    exit 1
}

Write-Output "Created upload job with ID: $jobId"
Read-Host "Press Enter to upload documents for this job"

Write-Output "Uploading documents..."
Write-Output ""

for ($i = 0; $i -lt $existingFiles.Count; $i++) {
    $filePath = $existingFiles[$i]
    $uploadUrl = if ($i -lt $uploadUrls.Count) { $uploadUrls[$i] } else { $null }
    $fileName = [System.IO.Path]::GetFileName($filePath)

    if ([string]::IsNullOrWhiteSpace($uploadUrl)) {
        Write-Output "Skipping $fileName - no upload URL found"
        continue
    }

    $extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
    $contentType = switch ($extension) {
        ".docx" { "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }
        ".pdf" { "application/pdf" }
        ".html" { "text/html" }
        ".txt" { "text/plain" }
        ".jpg" { "image/jpeg" }
        ".jpeg" { "image/jpeg" }
        default { "application/octet-stream" }
    }

    Write-Output "Uploading $fileName..."

    Invoke-WebRequest `
        -Uri $uploadUrl `
        -Method PUT `
        -Headers @{
            "x-ms-blob-type" = "BlockBlob"
            "x-ms-meta-filename" = $fileName
        } `
        -ContentType $contentType `
        -InFile $filePath | Out-Null
}

Write-Output ""
Read-Host "The documents have been uploaded. Press Enter to update the job status"

$completeResponse = Invoke-WebRequest `
    -Uri "$apiUri/accounts/$accountId/upload/jobs/$jobId/actions/complete" `
    -Method POST `
    -Headers $headers

Write-Output ""
Write-Output "Bulk upload job has been completed. Response:"
Write-Output ""
Write-Output $completeResponse.Content
Write-Output ""
Write-Output "Done."
