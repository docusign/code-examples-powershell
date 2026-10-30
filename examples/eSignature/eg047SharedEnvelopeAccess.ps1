. "utils/invokeScript.ps1"

$apiUri = "https://demo.docusign.net/restapi"
$accountUri = "https://account-d.docusign.com"

# Shared envelope access
#
# This script uses the envelope id stored in config\ENVELOPE_ID.
# config\ENVELOPE_ID will be populated by running example eg002SigningViaEmail.ps1
# or can be entered manually.

$accessToken = Get-Content .\config\ds_access_token.txt
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Check that we have an envelope id
if ((Test-Path .\config\ENVELOPE_ID) -eq $False) {
    Write-Output ""
    Write-Output "PROBLEM: An envelope id is needed. Fix: execute script eg002SigningViaEmail.ps1"
    Write-Output ""
    exit 1
}
$envelopeId = Get-Content .\config\ENVELOPE_ID

$requestData = New-TemporaryFile
$response = New-TemporaryFile

#ds-snippet-start:eSign47Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:eSign47Step2

# Get user id of the currently logged user
Invoke-RestMethod `
    -Uri "${accountUri}/oauth/userinfo" `
    -Method 'GET' `
    -Headers @{
    'Cache-Control' = "no-store";
    'Pragma' = "cache";
    'Authorization' = "Bearer $accessToken";
    } `
    -OutFile $response

$userId = $(Get-Content $response | ConvertFrom-Json).sub

Write-Output ""
$agentName = Read-Host "Please enter the name of the new agent"
Write-Output ""
$agentEmail = Read-Host "Please enter the email address of the new agent"
Write-Output ""
$activation = Read-Host "Please input an activation code for the new agent. Save this code. You'll need it when activating the new agent."

Write-Output ""
Write-Output "Checking whether a user with this email already exists in the account..."

# Look for an active user with this email
$agentUserId = $null
try {
    $existingUsers = Invoke-RestMethod `
        -Uri "${apiUri}/v2.1/accounts/${accountId}/users?email=$([uri]::EscapeDataString($agentEmail))&status=Active" `
        -Method 'GET' `
        -Headers $headers `
        -ErrorAction Stop

    $matchedUser = @($existingUsers.users) | Where-Object { $_.email -eq $agentEmail } | Select-Object -First 1
    if ($matchedUser) {
        $agentUserId = $matchedUser.userId
    }
} catch {
    # User not found - continue and create a new one
}

if ($agentUserId) {
    Write-Output ""
    Write-Output "An active user with this email was found. Using the existing user as the agent."
} else {
    Write-Output ""
    Write-Output "No active user with this email was found. Creating a new agent..."

    #ds-snippet-start:eSign47Step3
    # Create a new agent in the account
    @{
        newUsers = @(
            @{
                activationAccessCode = $activation;
                userName = $agentName;
                email = $agentEmail;
            };
        );
    } | ConvertTo-Json -Depth 32 > $requestData

    Invoke-RestMethod `
        -Uri "${apiUri}/v2.1/accounts/${accountId}/users" `
        -Method 'POST' `
        -Headers $headers `
        -InFile (Resolve-Path $requestData).Path `
        -OutFile $response

    Write-Output ""
    Write-Output "Response:"
    Write-Output ""
    Get-Content $response

    $agentUserId = $(Get-Content $response | ConvertFrom-Json).newUsers.userId
    #ds-snippet-end:eSign47Step3

    Write-Output ""
    Write-Output "Agent has been created. Please go to the agent's email to activate the agent, and press 1 to continue the example: "

    $choice = Read-Host
    if ($choice -ne "1") {
        Write-Output "Closing the example... "
        exit 1
    }
}

# Sharing the envelope with the agent
#ds-snippet-start:eSign47Step4
$body = @{
    shares = @(
        @{
            agentUser = @{
                userId = $agentUserId;
                accountId = $accountId;
            };
            permission = "manage";
            customMessage = "This envelope is shared with you.";
        };
    );
} | ConvertTo-Json -Depth 32

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/shares" `
    -Method 'POST' `
    -Headers $headers `
    -Body $body `
    -OutFile $response
#ds-snippet-end:eSign47Step4

Write-Output ""
Write-Output "Response:"
Write-Output ""
Get-Content $response

# Principal is told to log out and log in as the new agent
Write-Output ""
Write-Output "Please go to the principal's developer account at admindemo.docusign.com and log out, then come back to this terminal. Press 1 to continue: "

$choice = Read-Host
if ($choice -ne "1") {
    Write-Output "Closing the example... "
    exit 1
}

Invoke-Script -Command "`".\utils\sharedAccess.ps1`""

$accessToken = Get-Content .\config\ds_access_token.txt
$accountId = Get-Content .\config\API_ACCOUNT_ID

#ds-snippet-start:eSign47Step5
try {
    # Make the API call as the agent to get the envelopes shared with them
    $fromDate = ((Get-Date).AddDays(-10d)).ToString("yyyy-MM-ddThh:mm:ssK")

    $response = New-TemporaryFile

    Invoke-RestMethod `
        -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/shared" `
        -Method 'GET' `
        -Headers @{
        'Authorization' = "Bearer $accessToken";
        'Content-Type'  = "application/json";
    } `
        -Body @{ "from_date" = ${fromDate} } `
        -OutFile $response

    if ([string]::IsNullOrEmpty((Get-Content $response -Raw))) {
        Write-Output ""
        Write-Output "Response body is empty because no envelopes have been shared with the agent."
    } else {
        Write-Output ""
        Write-Output "Response:"
        Write-Output ""

        Get-Content $response
    }
    #ds-snippet-end:eSign47Step5
} catch {
    Write-Output "Unable to retrieve envelopes."

    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}

# cleanup
Remove-Item $requestData
Remove-Item $response

Write-Output ""
Write-Output "Done."
