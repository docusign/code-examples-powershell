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

#ds-snippet-start:ConnectedFields1Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:ConnectedFields1Step2

#ds-snippet-start:ConnectedFields1Step3
Invoke-RestMethod `
    -Uri "${apiUri1}/v1/accounts/${accountId}/connected-fields/tab-groups" `
    -Method 'GET' `
    -Headers $headers `
    -OutFile $response
#ds-snippet-end:ConnectedFields1Step3

#ds-snippet-start:ConnectedFields1Step4
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
        $_.tabs -and ($_.tabs | Where-Object { 
            ($_.extensionData.actionContract -like "*Verify*") -or 
            ($_.PSObject.Properties['tabLabel'] -and $_.tabLabel -like "*connecteddata*")
        })
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
        return $selectedData
    } else {
        Write-Host "Invalid choice. Exiting."
        exit 1
    }
}

function Parse-VerificationData {
    param (
        $selectedAppId,
        $tab
    )

    $connectionKeyData   = ''
    $connectionValueData = ''
    if ($tab.extensionData.connectionInstances) {
        $connectionKeyData   = $tab.extensionData.connectionInstances[0].connectionKey
        $connectionValueData = $tab.extensionData.connectionInstances[0].connectionValue
    }

    # Extract required fields from the first element
    $extractedData = @{
        appId                = $selectedAppId
        extensionGroupId     = $tab.extensionData.extensionGroupId
        publisherName        = $tab.extensionData.publisherName
        applicationName      = $tab.extensionData.applicationName
        actionName           = $tab.extensionData.actionName
        actionInputKey       = $tab.extensionData.actionInputKey
        actionContract       = $tab.extensionData.actionContract
        extensionName        = $tab.extensionData.extensionName
        extensionContract    = $tab.extensionData.extensionContract
        requiredForExtension = $tab.extensionData.requiredForExtension
        tabLabel             = $tab.tabLabel
        connectionKey        = $connectionKeyData
        connectionValue      = $connectionValueData
    }

    return $extractedData
}

$filteredData = Extract-VerifyInfo -responseFile $response

$selectedApp = Prompt-UserChoice -jsonData $filteredData
#ds-snippet-end:ConnectedFields1Step4

Write-Output "Sending the envelope request to Docusign..."

# Fetch doc and encode
$docPath = ".\demo_documents\World_Wide_Corp_Lorem.pdf"
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path $docPath))) > $docBase64

# Construct the request body
#ds-snippet-start:ConnectedFields1Step5
function Get-Extension-Data {
    param (
        $verificationData
    )

    return @{
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
        extensionPolicy      = "MustVerifyToSign";
        connectionInstances  = @(
            @{
                connectionKey   = $verificationData.connectionKey;
                connectionValue = $verificationData.connectionValue;
            };
        );
    };
}

function Make-Text-Tab {
    param (
        $verificationData,
        $extensionData,
        $textTabCount
    )

    return @{
        requireInitialOnSharedChange = "false";
        requireAll                   = "false";
        name                         = $verificationData.applicationName;
        required                     = "true";
        locked                       = "false";
        disableAutoSize              = "false";
        maxLength                    = "4000";
        tabLabel                     = $verificationData.tabLabel;
        font                         = "lucidaconsole";
        fontColor                    = "black";
        fontSize                     = "size9";
        documentId                   = "1";
        recipientId                  = "1";
        pageNumber                   = "1";
        xPosition                    = [string](70 + 100 * [math]::Floor($textTabCount / 10));
        yPosition                    = [string](560 + 20 * ($textTabCount % 10));
        width                        = "84";
        height                       = "22";
        templateRequired             = "false";
        tabType                      = "text";
        tooltip                      = $verificationData.actionInputKey;
        extensionData                = $extensionData
    };
}

function Make-Text-Tab-List {
    param (
        $app
    )

    $text_tabs = @()
    foreach ($tab in $app.tabs | Where-Object { $_.tabLabel -notlike '*SuggestionInput*' }) {
        $verificationData = Parse-VerificationData -selectedAppId $app.appId -tab $tab
        $extensionData = Get-Extension-Data -verificationData $verificationData

        $text_tab = Make-Text-Tab -verificationData $verificationData -extensionData $extensionData -textTabCount $text_tabs.Count
        $text_tabs += $text_tab
    }

    return $text_tabs
}

$textTabs = Make-Text-Tab-List -app $selectedApp

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
                    textTabs = @($textTabs);
                };
            };
        );
    };
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:ConnectedFields1Step5

#ds-snippet-start:ConnectedFields1Step6
Invoke-RestMethod `
    -Uri "${apiUri2}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response
#ds-snippet-end:ConnectedFields1Step6

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
