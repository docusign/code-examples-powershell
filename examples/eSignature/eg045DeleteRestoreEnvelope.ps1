$apiUri = "https://demo.docusign.net/restapi"

# Delete and Restore an Envelope

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json


# Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile

$recycle_bin_folder_id = "recyclebin"
$sent_items_folder_id = "sentitems"

Write-Output "Select the envelope ID to use for the delete and restore operations."
if (Test-Path .\config\ENVELOPE_ID) {
    $envelopeIdFromFile = Get-Content .\config\ENVELOPE_ID

    $userSavedEnvelope = Read-Host "Use the envelope ID from 'config/ENVELOPE_ID' (${envelopeIdFromFile})? (y/n)"
    switch ($userSavedEnvelope.ToLower()) {
        "y" {
            $envelopeId = $envelopeIdFromFile
        }
        default {
            $envelopeId = Read-Host "Please enter the new envelope ID"
        }
    }
} else {
    $envelopeId = Read-Host "No envelope ID found. Please enter the envelope ID"
}

if (-not $envelopeId) {
    Write-Output "ERROR: No envelope ID was provided"
    exit 1
}

Write-Output "Deleting the Envelope with ID: ${envelopeId}"
Write-Output "Sending PUT request to Docusign..."
Write-Output "Results:"

#ds-snippet-start:eSign45Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:eSign45Step2

# Concatenate the different parts of the request
#ds-snippet-start:eSign45Step3
@{
    envelopeIds = @("$envelopeId")
} | ConvertTo-Json -Depth 32 > $requestData
#ds-snippet-end:eSign45Step3

# Create and send the folders request
#ds-snippet-start:eSign45Step4
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/folders/${recycle_bin_folder_id}" `
    -Method 'PUT' `
    -Headers $headers `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response `
#ds-snippet-end:eSign45Step4

Write-Output "The deleted envelope is now in your Docusign Recycle Bin."
Write-Output "You can check your web app to confirm the deletion."

Read-Host "Press Enter to proceed with restoring the envelope from the Recycle Bin..."
$destinationFolderName = Read-Host "Please enter the name of the folder to undelete the envelope to (e.g., 'Sent Items') or press Enter to use the default"

if (-not $destinationFolderName) {
    $destinationFolderName = "Sent Items"
    Write-Output "The undeleted item will be moved to the Sent Items folder"
}

Write-Output "Searching for folder with name: '${destinationFolderName}'..."

#ds-snippet-start:eSign45Step5
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/folders" `
    -Method 'GET' `
    -Headers $headers `
    -OutFile $response

$folders = $(Get-Content $response | ConvertFrom-Json).folders
$folder = $folders | Where-Object { $_.name -eq $destinationFolderName }
#ds-snippet-end:eSign45Step5

if ($folder) {
    $folderId = $folder.folderId
} else {
    Write-Output "ERROR: Could not find a folder with the name '${destinationFolderName}'. Please check the spelling."
}

Write-Output "Found folder ID: ${folderId} for folder name: '${destinationFolderName}'"

Write-Output "Restoring the Envelope from Recycle Bin to the '${destinationFolderName}' folder."
Write-Output "Sending PUT request to Docusign..."
Write-Output "Results:"

#ds-snippet-start:eSign45Step6
@{
    envelopeIds  = @("$envelopeId");
    fromFolderId = "$recycle_bin_folder_id"
} | ConvertTo-Json -Depth 32 > $requestData

# Create and send the folders request
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/folders/${folderId}" `
    -Method 'PUT' `
    -Headers $headers `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response
#ds-snippet-end:eSign45Step6

Write-Output "The envelope has been undeleted and is now in your '${destinationFolderName}' folder."

# cleanup
Remove-Item $requestData
Remove-Item $response

Write-Output "Done."
