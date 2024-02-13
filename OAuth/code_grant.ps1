param(
  [Parameter(Mandatory = $true)]
  [string]$clientId,
  [Parameter(Mandatory = $true)]
  [string]$clientSecret,
  [Parameter(Mandatory = $true)]
  [string]$apiVersion,
  [Parameter(Mandatory = $true)]
  [string]$targetAccountId
  )

$PORT = '8080'
$IP = 'localhost'

$accessTokenFile = [System.IO.Path]::Combine($PSScriptRoot, "..\config\ds_access_token.txt")
$accountIdFile = [System.IO.Path]::Combine($PSScriptRoot, "..\config\API_ACCOUNT_ID")

$state = [Convert]::ToString($(Get-Random -Maximum 1000000000), 16)

if($apiVersion -eq "rooms"){
  $scopes = "signature%20dtr.rooms.read%20dtr.rooms.write%20dtr.documents.read%20dtr.documents.write%20dtr.profile.read%20dtr.profile.write%20dtr.company.read%20dtr.company.write%20room_forms"
}
elseif (($apiVersion -eq "eSignature") -or ($apiVersion -eq "idEvidence")){
  $scopes = "signature"
}
elseif ($apiVersion -eq "click") {
  $scopes = "click.manage%20click.send%20signature"
}
elseif ($apiVersion -eq "monitor") {
  $scopes = "signature impersonation"
}
elseif ($apiVersion -eq "admin") {
  $scopes = "signature%20organization_read%20group_read%20permission_read%20user_read%20user_write%20account_read%20domain_read%20identity_provider_read%20user_data_redact%20asset_group_account_read%20asset_group_account_clone_write%20asset_group_account_clone_read"
}
elseif ($apiVersion -eq "notary") {
  $scopes = "signature%20organization_read%20notary_read%20notary_write"
}
elseif ($apiVersion -eq "maestro") {
  $scopes = "signature%20aow_manage"
}
elseif ($apiVersion -eq "webForms") {
  $scopes = "signature%20webforms_read%20webforms_instance_read%20webforms_instance_write"
}


$authorizationEndpoint = "https://account-d.docusign.com/oauth/"
$redirectUri = "http://${IP}:${PORT}/authorization-code/callback"
$redirectUriEscaped = [Uri]::EscapeDataString($redirectURI)
$authorizationURL = "${authorizationEndpoint}auth?response_type=code&scope=$scopes&client_id=$clientId&state=$state&redirect_uri=$redirectUriEscaped"


# Request the authorization code
# Use Http Server
$http = New-Object System.Net.HttpListener

# Hostname and port to listen on

$http.Prefixes.Add($redirectURI + "/")
try {
# Start the Http Server
$http.Start()

}
catch {
    Write-Error "OAuth listener failed. Is port 8080 in use by another program?" -ErrorAction Stop
}

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

    # Get context
    $Regex = [Regex]::new("(?<=code=)(.*)(?=&state)")
    $Match = $Regex.Match($context.Request.Url)
    if ($Match.Success) {
      $authorizationCode = $Match.Value
    }

    $http.Stop()
  }
}

# Obtain the access token
# Preparing an Authorization header which contains your integration key and secret key
$authorizationHeader = "${clientId}:${clientSecret}"

# Convert the Authorization header into base64
$authorizationHeaderBytes = [System.Text.Encoding]::UTF8.GetBytes($authorizationHeader)
$authorizationHeaderKey = [System.Convert]::ToBase64String($authorizationHeaderBytes)

try {
  Write-Output "Getting an access token..."
  $accessTokenResponse = Invoke-RestMethod `
    -Uri "$authorizationEndpoint/token" `
    -Method "POST" `
    -Headers @{ "Authorization" = "Basic $authorizationHeaderKey" } `
    -Body @{
    "grant_type" = "authorization_code";
    "code"       = "$authorizationCode"
  }
  $accessToken = $accessTokenResponse.access_token
  Write-Output "Access token: $accessToken"
  Write-Output $accessToken > $accessTokenFile
  Write-Output "Access token has been written to $accessTokenFile file..."

  Write-Output "Getting an account id..."
  $userInfoResponse = Invoke-RestMethod `
    -Uri "$authorizationEndpoint/userinfo" `
    -Method "GET" `
    -Headers @{ "Authorization" = "Bearer $accessToken" }
  
  if ($targetAccountId -ne "TARGET_ACCOUNT_ID") {
    $targetAccountFound = "false";
    foreach ($account_info in $userInfoResponse.accounts) {
        if ($account_info.account_id -eq $targetAccountId) {
            $accountId = $account_info.account_id;
            $targetAccountFound = "true";
            break;
        }
    }

    if ($targetAccountFound -eq "false") {
      Write-Error "Targeted Account with Id $targetAccountId not found." -ErrorAction Stop;
    }
  } else {
      foreach ($account_info in $userInfoResponse.accounts) {
          if ($account_info.is_default -eq "true") {
            $accountId = $account_info.account_id;
            break;
          }
      }
  }

  Write-Output "Account id: $accountId"
  Write-Output $accountId > $accountIdFile
  Write-Output "Account id has been written to $accountIdFile file..."
}
catch {
  Write-Error $_
}
