$apiUri = "https://demo.docusign.net/restapi"

$accessToken = Get-Content .\config\ds_access_token.txt
$accountId = Get-Content .\config\API_ACCOUNT_ID

Write-Output "Checking to see if the template already exists in your account..."

$templateName = "Web Form Example Template"
$response = New-TemporaryFile

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/templates" `
    -Method 'GET' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -Body @{ 'search_text' = $templateName } `
    -OutFile $response

$templateId = $(Get-Content $response | ConvertFrom-Json).envelopeTemplates.templateId

Write-Output "Did we find any templateIds?: $templateId"

if (-not ([string]::IsNullOrEmpty($templateId))) {
    Write-Output "Your account already includes the '${templateName}' template."
    Write-Output "${templateId}" > .\config\WEB_FORM_TEMPLATE_ID
    Remove-Item $response
    Write-Output "Done."
    exit 0
}

$requestData = New-TemporaryFile
$requestDataTemp = New-TemporaryFile
$doc1Base64 = New-TemporaryFile

Write-Output "Sending the template create request to DocuSign..."

[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents/World_Wide_Corp_Web_Form.pdf"))) > $doc1Base64

$json = @"
{
    "description": "Example template created via the API",
    "name": "Web Form Example Template",
    "shared": "false",
    "documents": [
        {
            "documentBase64": "$(Get-Content $doc1Base64)",
            "documentId": "1",
            "fileExtension": "pdf",
            "name": "World_Wide_Web_Form"
        }
    ],
    "emailSubject": "Please sign this document",
    "recipients": {
        "signers": [
            {
                "recipientId": "1",
                "roleName": "signer",
                "routingOrder": "1",
                "tabs": {
                    "checkboxTabs": [
                        {
                            "documentId": "1",
                            "tabLabel": "Yes",
                            "anchorString": "/SMS/",
                            "anchorUnits": "pixels",
                            "anchorXOffset": "0",
                            "anchorYOffset": "0"
                        }
                    ],
                    "signHereTabs": [
                        {
                            "documentId": "1",
                            "tabLabel": "Signature",
                            "anchorString": "/SignHere/",
                            "anchorUnits": "pixels",
                            "anchorXOffset": "20",
                            "anchorYOffset": "10"
                        }
                    ],
                    "textTabs": [
                        {
                            "documentId": "1",
                            "tabLabel": "FullName",
                            "anchorString": "/FullName/",
                            "anchorUnits": "pixels",
                            "anchorXOffset": "0",
                            "anchorYOffset": "0"
                        },
                        {
                            "documentId": "1",
                            "tabLabel": "PhoneNumber",
                            "anchorString": "/PhoneNumber/",
                            "anchorUnits": "pixels",
                            "anchorXOffset": "0",
                            "anchorYOffset": "0"
                        },
                        {
                            "documentId": "1",
                            "tabLabel": "Company",
                            "anchorString": "/Company/",
                            "anchorUnits": "pixels",
                            "anchorXOffset": "0",
                            "anchorYOffset": "0"
                        },
                        {
                            "documentId": "1",
                            "tabLabel": "JobTitle",
                            "anchorString": "/Title/",
                            "anchorUnits": "pixels",
                            "anchorXOffset": "0",
                            "anchorYOffset": "0"
                        }
                    ],
                    "dateSignedTabs": [
                        {
                            "documentId": "1",
                            "tabLabel": "DateSigned",
                            "anchorString": "/Date/",
                            "anchorUnits": "pixels",
                            "anchorXOffset": "0",
                            "anchorYOffset": "0"
                        }
                    ]
                }
            }
        ]
    },
    "status": "created"
}
"@

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/templates" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -Body $json `
    -OutFile $response

Write-Output "Results:"
Get-Content $response

$templateId = $(Get-Content $response | ConvertFrom-Json).templateId

Write-Output "Template '${templateName}' was created! Template ID ${templateId}."
Write-Output ${templateId} > .\config\WEB_FORM_TEMPLATE_ID

Remove-Item $requestData
Remove-Item $requestDataTemp
Remove-Item $response
Remove-Item $doc1Base64

Write-Output "Done."
