param(
    [Parameter(Mandatory = $true)]
    [string]$clientId,
    [Parameter(Mandatory = $true)]
    [string]$apiVersion)

# Reference dependencies
. ([System.IO.Path]::Combine($PSScriptRoot, "..\Install-NugetPackage.ps1"))

# Load required assemblies
Install-NugetPackage DerConverter '3.0.0.82'
Install-NugetPackage PemUtils '3.0.0.82'

New-Item "config\ds_access_token.txt" -Force

if (!(test-path "..\config\private.key")){
  Write-Error "`n Error: First create an RSA keypair on your integration key and copy the private_key into the file `config/private.key` and save it" -ErrorAction Stop
  exit 1
}
$privateKeyPath = [System.IO.Path]::Combine($PSScriptRoot, "..\config\private.key") | Resolve-Path 
$outputFile = [System.IO.Path]::Combine($PSScriptRoot, "..\config\ds_access_token.txt") | Resolve-Path 
$accountIdFile = [System.IO.Path]::Combine($PSScriptRoot, "..\config\API_ACCOUNT_ID")

# Get required variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$userId = $variables.IMPERSONATION_USER_GUID
$INTEGRATION_KEY_JWT = $variables.INTEGRATION_KEY_JWT
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))

if ($apiVersion -eq "rooms") {
    $scopes = "signature%20impersonation%20dtr.rooms.read%20dtr.rooms.write%20dtr.documents.read%20dtr.documents.write%20dtr.profile.read%20dtr.profile.write%20dtr.company.read%20dtr.company.write%20room_forms"
  } elseif ($apiVersion -eq "eSignature") {
    $scopes = "signature%20impersonation"
  } elseif ($apiVersion -eq "click") {
    $scopes = "click.manage"
  }
  elseif ($apiVersion -eq "monitor") {
  $scopes = "signature impersonation"
  }

# Step 1. Request application consent
$PORT = '8080'
$IP = 'localhost'
$state = [Convert]::ToString($(Get-Random -Maximum 1000000000), 16)
$authorizationEndpoint = "https://account-d.docusign.com/oauth/"
$redirectUri = "http://${IP}:${PORT}/authorization-code/callback"
$redirectUriEscaped = [Uri]::EscapeDataString($redirectURI)
$authorizationURL = "${authorizationEndpoint}auth?scope=$scopes&redirect_uri=$redirectUriEscaped&client_id=$clientId&state=$state&response_type=code"

Write-Output "The authorization URL is: $authorizationURL"
Write-Output ""

# Request the authorization code
# Use Http Server
$http = New-Object System.Net.HttpListener

# Hostname and port to listen on
$http.Prefixes.Add($redirectURI + "/")

# Start the Http Server
$http.Start()

if ($http.IsListening) {
    Write-Output "Open the following URL in a browser to continue:" $authorizationURL
    Start-Process $authorizationURL
}

while ($http.IsListening) {
    $context = $http.GetContext()

    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.Url.LocalPath -match '/authorization-code/callback') {
        # write-host "Check context"
        # write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'
        [string]$html = '
          <html lang="en">
          <head>
            <meta charset="utf-8">
            <title></title>
          </head>
          <body>
          Ok. You may close this tab and return to the shell. This window closes automatically in five seconds.
          <script type="text/javascript">
            setTimeout(
            function ( )
            {
              self.close();
            }, 5000 );
            </script>
          </body>
          </html>
          '
        # Respond to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # Convert HTML to bytes
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) # Stream HTML to browser
        $context.Response.OutputStream.Close() # Close the response

        Start-Sleep 10
        $http.Stop()
    }
}

# Step 2. Create a JWT
$decJwtHeader = [ordered]@{
    'typ' = 'JWT';
    'alg' = 'RS256'
} | ConvertTo-Json -Compress

# Remove %20 from scope string
$scopes = $scopes -replace '%20',' '

$decJwtPayLoad = [ordered]@{
    'iss'   = $INTEGRATION_KEY_JWT;
    'sub'   = $userId;
    'iat'   = $timestamp;
    'exp'   = $timestamp + 3600;
    'aud'   = 'account-d.docusign.com';
    'scope' = $scopes
} | ConvertTo-Json -Compress

$encJwtHeaderBytes = [System.Text.Encoding]::UTF8.GetBytes($decJwtHeader)
$encJwtHeader = [System.Convert]::ToBase64String($encJwtHeaderBytes) -replace '\+', '-' -replace '/', '_' -replace '='

$encJwtPayLoadBytes = [System.Text.Encoding]::UTF8.GetBytes($decJwtPayLoad)
$encJwtPayLoad = [System.Convert]::ToBase64String($encJwtPayLoadBytes) -replace '\+', '-' -replace '/', '_' -replace '='

$jwtToken = "$encJwtHeader.$encJwtPayLoad"

$keyStream = [System.IO.File]::OpenRead($privateKeyPath)
$keyReader = [PemUtils.PemReader]::new($keyStream)

$rsaParameters = $keyReader.ReadRsaKey()
$rsa = [System.Security.Cryptography.RSA]::Create($rsaParameters)

$tokenBytes = [System.Text.Encoding]::ASCII.GetBytes($jwtToken)
$signedToken = $rsa.SignData(
    $tokenBytes,
    [System.Security.Cryptography.HashAlgorithmName]::SHA256,
    [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)

$signedBase64Token = [System.Convert]::ToBase64String($signedToken) -replace '\+', '-' -replace '/', '_' -replace '='

$jwtToken = "$encJwtHeader.$encJwtPayLoad.$signedBase64Token"

# Step 3. Obtain the access token
try {
    $authorizationEndpoint = "https://account-d.docusign.com/oauth/"
    $tokenResponse = Invoke-WebRequest `
        -Uri "$authorizationEndpoint/token" `
        -Method "POST" `
        -Body "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=$jwtToken"
    $accessToken = ($tokenResponse | ConvertFrom-Json).access_token
    Write-Output $accessToken > $outputFile
    Write-Output "Access token has been written to $outputFile file..."

    Write-Output "Getting an account id..."
    $userInfoResponse = Invoke-RestMethod `
        -Uri "$authorizationEndpoint/userinfo" `
        -Method "GET" `
        -Headers @{ "Authorization" = "Bearer $accessToken" }
    $accountId = $userInfoResponse.accounts[0].account_id
    Write-Output "Account id: $accountId"
    Write-Output $accountId > $accountIdFile
    Write-Output "Account id has been written to $accountIdFile file..."
}
catch {
    Write-Error $_
}
