$configFile = ".\config\settings.json"

if ((Test-Path $configFile) -eq $False) {
    Write-Output "Error: "
    Write-Output "First copy the file '.\config\settings.example.json' to '$configFile'."
    Write-Output "Next, fill in your API credentials, Signer name and email to continue."
}

# Get required environment variables from .\config\settings.json file
$config = Get-Content $configFile -Raw | ConvertFrom-Json

Enum AuthType {
  CodeGrant = 1;
  JWT = 2;
  Exit = 3;
}

$AuthTypeView = $null;
do {
    Write-Output ""
    Write-Output 'Choose an OAuth Strategy: '
    Write-Output "$([int][AuthType]::CodeGrant)) Authorization Code Grant"
    Write-Output "$([int][AuthType]::JWT)) Json Web Token (JWT)"
    Write-Output "$([int][AuthType]::Exit)) Exit"
    [int]$AuthTypeView = Read-Host "Choose an OAuth Strategy. Then log in as the new user that you just created."
} while (-not [AuthType]::IsDefined([AuthType], $AuthTypeView));

if ($AuthTypeView -eq [AuthType]::Exit) {
  exit 1;
}
elseif ($AuthTypeView -eq [AuthType]::CodeGrant) {
  powershell.exe -Command .\OAuth\code_grant.ps1 -clientId $($config.INTEGRATION_KEY_AUTH_CODE) -clientSecret $($config.SECRET_KEY) -apiVersion $("eSignature") -targetAccountId $($config.TARGET_ACCOUNT_ID)
  if ((Test-Path "./config/ds_access_token.txt") -eq $false) {
      Write-Error "Failed to retrieve OAuth Access token, check your settings.json and that port 8080 is not in use"  -ErrorAction Stop
  }
}
elseif ($AuthTypeView -eq [AuthType]::JWT) {
  powershell.exe -Command .\OAuth\jwt.ps1 -clientId $($config.INTEGRATION_KEY_AUTH_CODE) -apiVersion $("eSignature") -targetAccountId $($config.TARGET_ACCOUNT_ID)
  if ((Test-Path "./config/ds_access_token.txt") -eq $false) {
      Write-Error "Failed to retrieve OAuth Access token, check your settings.json and that port 8080 is not in use"  -ErrorAction Stop
  }
}
