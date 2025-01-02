$apiUri = "https://api-d.docusign.com/v1"
$configPath = ".\config\settings.json"
$tokenPath = ".\config\ds_access_token.txt"
$accountIdPath = ".\config\API_ACCOUNT_ID"
$agreementsPath = ".\config\AGREEMENTS.txt"

# Check if the agreements file exists and has content
if (-not (Test-Path $agreementsPath) -or -not (Get-Content $agreementsPath -ErrorAction SilentlyContinue)) {
  Write-Output "No agreements found in $agreementsPath."
  Write-Output "Please run Navigator example 1: List_Agreements first to get a list of agreements."
  exit 0
}

# Load the file into an array, separating each line into id and file name
$agreements = Get-Content -Path $agreementsPath | ForEach-Object {
  $parts = $_ -split '\s+'
  [PSCustomObject]@{
      Id = $parts[0]
      FileName = $parts[1]
  }
}

# Display the file names for selection
Write-Output "Please select an agreement:"
for ($i = 0; $i -lt $agreements.Count; $i++) {
  Write-Output "$($i + 1). $($agreements[$i].FileName)"
}

# Prompt user selection
do {
  $selection = Read-Host "Enter the number corresponding to your choice"

  if ($selection -match '^\d+$' -and $selection -gt 0 -and $selection -le $agreements.Count) {
      $chosenAgreement = $agreements[$selection - 1]
      $AGREEMENT_ID = $chosenAgreement.Id

      Write-Output "You selected: $($chosenAgreement.FileName)"
      Write-Output "AGREEMENT_ID: $AGREEMENT_ID"
      break
  }
  else {
      Write-Output "Invalid selection. Please try again."
  }
} while ($true)

# Get required variables from .\config\settings.json file
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$accessToken = Get-Content $tokenPath
$accountId = Get-Content $accountIdPath

#ds-snippet-start:Navigator2Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:Navigator2Step2

# List agreements
#ds-snippet-start:Navigator2Step3
$response = New-TemporaryFile
Invoke-RestMethod `
    -Uri "${apiUri}/accounts/${accountId}/agreements/${AGREEMENT_ID}" `
    -Method 'GET' `
    -Headers $headers `
    -OutFile $response

$responseContent = $(Get-Content $response | ConvertFrom-Json)
#ds-snippet-end:Navigator2Step3

Write-Host ""
Write-Output "Response: $(Get-Content -Raw $response)"




Write-Output ""
Write-Output "Done."
