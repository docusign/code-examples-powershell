$apiUri1 = "https://api-d.docusign.com"
$apiUri2 = "https://demo.docusign.net/restapi"
$configPath = ".\config\settings.json"
$tokenPath = ".\config\ds_access_token.txt"
$accountIdPath = ".\config\API_ACCOUNT_ID"

# Get required variables from .\config\settings.json file
$variables = Get-Content $configPath -Raw | ConvertFrom-Json

# 1. Obtain your OAuth token
$accessToken = Get-Content $tokenPath

# Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountID = Get-Content $accountIdPath

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$docBase64 = New-TemporaryFile

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")

Invoke-RestMethod `
    -Uri "${apiUri1}/v1/accounts/${accountId}/connected-fields/tab-groups" `
    -Method 'GET' `
    -Headers $headers `
    -OutFile $response

function Extract-VerifyInfo {
    param (
        [string]$responseFile
    )

    # Read the response file content
    $content = Get-Content $responseFile -Raw

    # Extract JSON
    $jsonStart = $content.IndexOf('[')
    if ($jsonStart -ge 0) {
        $json = $content.Substring($jsonStart) | ConvertFrom-Json
    } else {
        Write-Error "No JSON array found in the response."
        return
    }

    # Filter the JSON to keep only verification extension apps
    $filtered = $json | Where-Object { 
        $_.tabs -and ($_.tabs | Where-Object { $_.extensionData.actionContract -like "*Verify*" })
    }

    return $filtered | ConvertTo-Json -Depth 10
}

function Prompt-UserChoice {
    param (
        [string]$jsonData
    )

    if (-not $jsonData -or $jsonData -eq "[]") {
        Write-Host "No data verification were found in the account. Please install a data verification app."
        Write-Host "You can install a phone number verification extension app by copying the following link to your browser: "
        Write-Host "https://apps.docusign.com/app-center/app/d16f398f-8b9a-4f94-b37c-af6f9c910c04"
        exit 1
    }

    $data = $jsonData | ConvertFrom-Json

    # Extract unique app IDs and application names
    $uniqueApps = @{}
    foreach ($item in $data) {
        if ($item.appId -and $item.tabs[0].extensionData.applicationName) {
            $uniqueApps[$item.appId] = $item.tabs[0].extensionData.applicationName
        }
    }

    # If no unique apps are found
    if ($uniqueApps.Count -eq 0) {
        Write-Host "No valid apps found in the JSON data."
        exit 1
    }

    # Display available apps
    Write-Host "Please select an app by entering a number:"
    $appList = $uniqueApps.Keys | Sort-Object
    for ($i = 0; $i -lt $appList.Count; $i++) {
        Write-Host "$($i + 1). $($uniqueApps[$appList[$i]])"
    }

    # Get user choice
    $choice = Read-Host "Enter choice (1-$($appList.Count))"
    if ($choice -match "^\d+$" -and [int]$choice -ge 1 -and [int]$choice -le $appList.Count) {
        $chosenAppId = $appList[[int]$choice - 1]

        # Filter JSON data for the selected app ID
        $selectedData = $data | Where-Object { $_.appId -eq $chosenAppId }

        # Call another function to process selected data (assuming Parse-VerificationData exists)
        Parse-VerificationData -jsonData ($selectedData | ConvertTo-Json -Depth 10)
    } else {
        Write-Host "Invalid choice. Exiting."
        exit 1
    }
}

function Parse-VerificationData {
    param (
        [string]$jsonData
    )

    # Convert JSON string to PowerShell object
    $data = $jsonData | ConvertFrom-Json

    $connectionKeyData   = ''
    $connectionValueData = ''
    if ($data.tabs[0].extensionData.connectionInstances) {
        $connectionKeyData   = $data.tabs[0].extensionData.connectionInstances[0].connectionKey
        $connectionValueData = $data.tabs[0].extensionData.connectionInstances[0].connectionValue
    }

    # Extract required fields from the first element
    $extractedData = @{
        appId                = $data.appId
        extensionGroupId     = $data.tabs[0].extensionData.extensionGroupId
        publisherName        = $data.tabs[0].extensionData.publisherName
        applicationName      = $data.tabs[0].extensionData.applicationName
        actionName           = $data.tabs[0].extensionData.actionName
        actionInputKey       = $data.tabs[0].extensionData.actionInputKey
        actionContract       = $data.tabs[0].extensionData.actionContract
        extensionName        = $data.tabs[0].extensionData.extensionName
        extensionContract    = $data.tabs[0].extensionData.extensionContract
        requiredForExtension = $data.tabs[0].extensionData.requiredForExtension
        tabLabel             = ($data.tabs | ForEach-Object { $_.tabLabel }) -join ", "
        connectionKey        = $connectionKeyData
        connectionValue      = $connectionValueData
    }

    # Output the extracted information
    Write-Host "App ID: $($extractedData.appId)";
    Write-Host "Extension Group ID: $($extractedData.extensionGroupId)";
    Write-Host "Publisher Name: $($extractedData.publisherName)";
    Write-Host "Application Name: $($extractedData.applicationName)";
    Write-Host "Action Name: $($extractedData.actionName)";
    Write-Host "Action Contract: $($extractedData.actionContract)";
    Write-Host "Action Input Key: $($extractedData.actionInputKey)";
    Write-Host "Extension Name: $($extractedData.extensionName)";
    Write-Host "Extension Contract: $($extractedData.extensionContract)";
    Write-Host "Required for Extension: $($extractedData.requiredForExtension)";
    Write-Host "Tab Label: $($extractedData.tabLabel)";
    Write-Host "Connection Key: $($extractedData.connectionKey)";
    Write-Host "Connection Value: $($extractedData.connectionValue)";

    return $extractedData
}

$filteredData = Extract-VerifyInfo -responseFile $response

$verificationData = Prompt-UserChoice -jsonData $filteredData

Write-Output "Sending the envelope request to Docusign..."

# Fetch doc and encode
$docPath = ".\demo_documents\World_Wide_Corp_Lorem.pdf"
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path $docPath))) > $docBase64

# Construct the request body
@{
    emailSubject = "Please sign this document";
    documents    = @(
        @{
            documentBase64 = "$(Get-Content $docBase64)";
            name           = "Lorem Ipsum";
            fileExtension  = "pdf";
            documentId     = "1";
        };
    );
    status      = "sent";
    recipients  = @{
        signers = @(
            @{
                email        = $variables.SIGNER_EMAIL;
                name         = $variables.SIGNER_NAME;
                recipientId  = "1";
                routingOrder = "1";
                tabs = @{
                    signHereTabs = @(
                        @{
                            anchorString  = "/sn1/";
                            anchorUnits   = "pixels";
                            anchorXOffset = "20";
                            anchorYOffset = "10";
                        };
                    );
                    textTabs = @(
                        @{
                            requireInitialOnSharedChange = $false;
                            requireAll                   = $false;
                            name                         = $verificationData.applicationName;
                            required                     = $true;
                            locked                       = $false;
                            disableAutoSize              = $false;
                            maxLength                    = 4000;
                            tabLabel                     = $verificationData.tabLabel;
                            font                         = "lucidaconsole";
                            fontColor                    = "black";
                            fontSize                     = "size9";
                            documentId                   = "1";
                            recipientId                  = "1";
                            pageNumber                   = "1";
                            xPosition                    = "273";
                            yPosition                    = "191";
                            width                        = "84";
                            height                       = "22";
                            templateRequired             = $false;
                            tabType                      = "text";
                            extensionData = @{
                                extensionGroupId     = $verificationData.extensionGroupId;
                                publisherName        = $verificationData.publisherName;
                                applicationId        = $verificationData.appId;
                                applicationName      = $verificationData.applicationName;
                                actionName           = $verificationData.actionName;
                                actionContract       = $verificationData.actionContract;
                                extensionName        = $verificationData.extensionName;
                                extensionContract    = $verificationData.extensionContract;
                                requiredForExtension = $verificationData.requiredForExtension;
                                actionInputKey       = $verificationData.actionInputKey;
                                extensionPolicy      = "None";
                                connectionInstances  = @(
                                    @{
                                        connectionKey   = $verificationData.connectionKey;
                                        connectionValue = $verificationData.connectionValue;
                                    };
                                );
                            };
                        };
                    );
                };
            };
        );
    };
} | ConvertTo-Json -Depth 32 > $requestData

Invoke-RestMethod `
    -Uri "${apiUri2}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response

Write-Output "Response: $(Get-Content -Raw $response)"

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId

# Save the envelope id for use by other scripts
Write-Output "EnvelopeId: $envelopeId"
Write-Output $envelopeId > .\config\ENVELOPE_ID

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $docBase64

Write-Output "Done. When signing the envelope, ensure the connection to your data verification extension app is active."
