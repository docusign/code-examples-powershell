. "../utils/invokeScript.ps1"

$ErrorActionPreference = "Stop" # force stop on failure

$configFile = "..\config\settings.json"

if ((Test-Path $configFile) -eq $False) {
    Write-Output "Error: "
    Write-Output "First copy the file '..\config\settings.example.json' to '$configFile'."
    Write-Output "Next, fill in your API credentials, Signer name and email to continue."
}

# Get required environment variables from ..\config\settings.json file
$config = Get-Content $configFile -Raw | ConvertFrom-Json

function startQuickACG {
    Write-Output ''
    Write-Output "Authentication in progress, please wait"
    Write-Output ''
    Invoke-Script -Command "`"..\OAuth\code_grant.ps1`" -clientId `"$($config.INTEGRATION_KEY_AUTH_CODE)`" -clientSecret `"$($config.SECRET_KEY)`" -apiVersion $("eSignature") -targetAccountId `"$($config.TARGET_ACCOUNT_ID)`""
    Write-Output ''

    if ((Test-Path "../config/ds_access_token.txt") -eq $true) {
        Invoke-Script -Command "`"..\eg001EmbeddedSigning.ps1`""
        Write-Output ''
        startSignature
    }
    else {
        Write-Error "Failed to retrieve OAuth Access token, check your settings.json and that port 8080 is not in use"  -ErrorAction Stop
    }
}

function startSignature {
    do {
        # Preparing a list of menu options
        Enum MenuOptions {
            Embedded_Signing = 1;
            Exit = 2;
        }

        $MenuOptionsView = $null;
        do {
            Write-Output ""
            Write-Output 'Pick the next action: '
            Write-Output "$([int][MenuOptions]::Embedded_Signing)) Rerun the embedded signing code example"
            Write-Output "$([int][MenuOptions]::Exit)) Exit"
            [int]$MenuOptionsView = Read-Host "Pick the next action"
        } while (-not [MenuOptions]::IsDefined([MenuOptions], $MenuOptionsView));

        if ($MenuOptionsView -eq [MenuOptions]::Embedded_Signing) {
            Invoke-Script -Command "`"..\eg001EmbeddedSigning.ps1`""
        } 
        elseif ($MenuOptionsView -eq [MenuOptions]::Exit) {
            exit 1
        }
    } until ($MenuOptionsView -eq [MenuOptions]::Exit)
    exit 1
}

Write-Output "Welcome to the DocuSign PowerShell Quick Authorization Code Grant Launcher"
startQuickACG
