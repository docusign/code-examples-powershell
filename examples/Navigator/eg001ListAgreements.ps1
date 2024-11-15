$apiUri = "https://api-d.docusign.com/v1"
$configPath = ".\config\settings.json"
$tokenPath = ".\config\ds_access_token.txt"
$accountIdPath = ".\config\API_ACCOUNT_ID"
$agreementsPath = ".\config\AGREEMENTS.txt"

# Get required variables from .\config\settings.json file
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$accessToken = Get-Content $tokenPath
$accountId = Get-Content $accountIdPath

#ds-snippet-start:Navigator1Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:Navigator1Step2

# List agreements
#ds-snippet-start:Navigator1Step3
$response = New-TemporaryFile
Invoke-RestMethod `
    -Uri "${apiUri}/accounts/${accountId}/agreements" `
    -Method 'GET' `
    -Headers $headers `
    -OutFile $response

$responseContent = $(Get-Content $response | ConvertFrom-Json)
#ds-snippet-end:Navigator1Step3

Write-Host ""
Write-Output "Response: $(Get-Content -Raw $response)"

# Clear the output file at the beginning
Clear-Content -Path $agreementsPath -ErrorAction SilentlyContinue

# Loop through each item in the 'data' array
foreach ($item in $responseContent.data) {
    # Extract id and file_name
    $id = $item.id
    $fileName = $item.file_name

    # Write the id and file_name to the output file
    "$id $fileName" | Out-File -FilePath $agreementsPath -Append
}

Write-Output ""
Write-Output "Done."
