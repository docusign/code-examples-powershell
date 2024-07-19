. "utils/invokeScript.ps1"

$apiUri = "https://demo.docusign.net/restapi"
$accountUri = "https://account-d.docusign.com"

$accessToken = Get-Content .\config\ds_access_token.txt
$accountId = Get-Content .\config\API_ACCOUNT_ID

$requestData = New-TemporaryFile
$requestDataTemp = New-TemporaryFile
$response = New-TemporaryFile

#ds-snippet-start:eSign43Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:eSign43Step2

Write-Output ""
$agentName = Read-Host "Please enter the name of the new agent"
Write-Output ""
$agentEmail = Read-Host "Please enter the email address of the new agent"
Write-Output ""
$activation = Read-Host "Please input an activation code for the new agent. Save this code. You'll need it when activating the new agent."

#ds-snippet-start:eSign43Step3
try {
    # Check, if the agent already exists
    Invoke-RestMethod `
        -Uri "${apiUri}/v2.1/accounts/${accountId}/users?email=${agentEmail}&status=Active" `
        -Method 'GET' `
        -Headers @{
            'Authorization' = "Bearer $accessToken";
            'Content-Type'  = "application/json";
        } `
        -OutFile $response
    
    Write-Output ""
    Write-Output "Response:"
    Write-Output ""
    Get-Content $response
    
    $agentUserId = $(Get-Content $response | ConvertFrom-Json).users.userId
} catch {   
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
        -Headers @{
        'Authorization' = "Bearer $accessToken";
        'Content-Type'  = "application/json";
    } `
        -InFile (Resolve-Path $requestData).Path `
        -OutFile $response
    
    Write-Output ""
    Write-Output "Response:"
    Write-Output ""
    Get-Content $response
    
    $agentUserId = $(Get-Content $response | ConvertFrom-Json).newUsers.userId
    #ds-snippet-end:eSign43Step3
}

Write-Output "" 
Write-Output "Agent has been created. Please go to the agent's email to activate the agent, and press 1 to continue the example: "

$choice = Read-Host
if ($choice -ne "1") {
    Write-Output "Closing the example... "
    exit 1
}

try {
    # Get user id of the currently logged user
    Invoke-RestMethod `
    -Uri "${accountUri}/oauth/userinfo" `
    -Method 'GET' `
    -Headers @{
    'Cache-Control' = "no-store";
    'Pragma' = "cache";
    'Authorization' = "Bearer $accessToken";
    } `
    -Body @{ "from_date" = ${fromDate} } `
    -OutFile $response

    $userId = $(Get-Content $response | ConvertFrom-Json).sub
} catch {
    Write-Output "Unable to retrieve Bulk Status."

    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}

#ds-snippet-start:eSign43Step4
$isUserActivated = 0;

do {
    try {
        # Check, if authorization exists
        Invoke-RestMethod `
            -Uri "${apiUri}/v2.1/accounts/${accountId}/users/${agentUserId}/authorizations/agent?permissions=manage" `
            -Method 'GET' `
            -Headers @{
                'Authorization' = "Bearer $accessToken";
                'Content-Type'  = "application/json";
            } `
            -OutFile $response

        if ([string]::IsNullOrEmpty($(Get-Content $response | ConvertFrom-Json).authorizations)) {
            # Sharing the envelope with the agent
            $body = @"
            {
                "agentUser":
                    {
                        "userId": "${agentUserId}",
                        "accountId": "${accountId}"
                    },
                "permission": "manage"
            }
"@ 

            Write-Output ""
            $uri = "${apiUri}/v2.1/accounts/${accountId}/users/${userId}/authorization"

            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.add("Authorization", "Bearer $accessToken")
            $headers.add("Content-Type", "application/json")

            Invoke-WebRequest -uri $uri -headers $headers -body $body -method POST -UseBasicParsing -OutFile $response
            
            Write-Output "Response:"
            Write-Output "$(Get-Content -Raw $response)"
        }

        $isUserActivated = 1;
        #ds-snippet-end:eSign43Step4
    } catch {
        Write-Output "Agent has been created. Please go to the agent's email to activate the agent, and press 1 to continue the example: "

        $choice = Read-Host
        if ($choice -ne "1") {
            Write-Output "Closing the example... "
            exit 1
        }
    }
} while (!$isUserActivated)

# Principal is told to log out and log in as the new agent
Write-Output "" 
Write-Output "Please go to the principal's developer account at admindemo.docusign.com and log out, then come back to this terminal. Press 1 to continue: "

$choice = Read-Host
if ($choice -ne "1") {
    Write-Output "Closing the example... "
    exit 1
}

Invoke-Script -Command "`".\utils\sharedAccess.ps1`""

#ds-snippet-start:eSign43Step5
try {
    # Make the API call to check the envelope
    # Get date in the ISO 8601 format
    $fromDate = ((Get-Date).AddDays(-10d)).ToString("yyyy-MM-ddThh:mm:ssK")

    $response = New-TemporaryFile

    Invoke-RestMethod `
        -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
        -Method 'GET' `
        -Headers @{
        'X-DocuSign-Act-On-Behalf' = $userId;
        'Authorization' = "Bearer $accessToken";
        'Content-Type'  = "application/json";
    } `
        -Body @{ "from_date" = ${fromDate} } `
        -OutFile $response

    if ([string]::IsNullOrEmpty($response))
    {
        Write-Output ""
        Write-Output "Response body is empty because there are no envelopes in the account. Please run example 2 and re-run this example." 
    } else {
        Write-Output ""
        Write-Output "Response:"
        Write-Output ""

        Get-Content $response
    }
   #ds-snippet-end:eSign43Step5
} catch {
    Write-Output "Unable to retrieve Bulk Status."

    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}

# cleanup
Remove-Item $requestData
Remove-Item $requestDataTemp
Remove-Item $response

Write-Output ""
Write-Output "Done."
