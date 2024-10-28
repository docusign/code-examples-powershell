. "utils/invokeScript.ps1"

$apiUri = "https://apps-d.docusign.com/api/webforms/v1.1"
$configPath = ".\config\settings.json"
$tokenPath = ".\config\ds_access_token.txt"
$accountIdPath = ".\config\API_ACCOUNT_ID"

# Get required variables from .\config\settings.json file
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$accessToken = Get-Content $tokenPath
$accountId = Get-Content $accountIdPath

# Create template for the Web Form from the API
Invoke-Script -Command "`".\utils\createWebFormTemplate.ps1`""

$templateId = Get-Content -Path ".\config\WEB_FORM_TEMPLATE_ID"

$webFormConfig = Get-Content -Raw demo_documents\web-form-config.json
$result = $webFormConfig -replace "template-id", $templateId
$result | Set-Content -Path demo_documents\web-form-config.json

Write-Host ""
Write-Host "Go to your Docusign account to create the Web Form. Go to 'Templates' in your developer account, select 'Start,' select 'Web Forms,' and choose 'Upload Web Form.' Upload the JSON config file 'web-form-config.json' found under the demo_documents folder of this project. You will need to activate the web form before proceeding. Press Continue after doing so."
$choice = Read-Host

#ds-snippet-start:WebForms1Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Content-Type", "application/json")
$headers.add("Accept", "application/json")
#ds-snippet-end:WebForms1Step2

# List web forms in account that match the name of the web form we just created
#ds-snippet-start:WebForms1Step3
$response = New-TemporaryFile
Invoke-RestMethod `
    -Uri "${apiUri}/accounts/${accountId}/forms?search=Web%20Form%20Example%20Template" `
    -Method 'GET ' `
    -Headers $headers `
    -OutFile $response

$formId = $(Get-Content $response | ConvertFrom-Json).items[0].id
#ds-snippet-end:WebForms1Step3

#ds-snippet-start:WebForms1Step4
$json = @"
{
    "clientUserId": "1234-5678-abcd-ijkl",
    "formValues": {
        "PhoneNumber": "555-555-5555",
        "Yes": ["Yes"],
        "Company": "Tally",
        "JobTitle": "Programmer Writer"
    },
    "expirationOffset": 3600
}
"@
#ds-snippet-end:WebForms1Step4

#ds-snippet-start:WebForms1Step5
Invoke-RestMethod `
    -Uri "${apiUri}/accounts/${accountId}/forms/${formId}/instances" `
    -Method 'POST' `
    -Headers $headers `
    -Body $json `
    -OutFile $response

$responseContent = $(Get-Content $response | ConvertFrom-Json)
#ds-snippet-end:WebForms1Step5

Write-Host ""
Write-Host "Response:"
Write-Host $responseContent

$formUrl = $responseContent.formUrl
$instanceToken = $responseContent.instanceToken
$integrationKey  = $config.INTEGRATION_KEY_AUTH_CODE

Invoke-Script -Command "./utils/startServerForWebFormsExample.ps1 -integrationKey $integrationKey -url $formUrl -instanceToken $instanceToken"

Write-Output ""
Write-Output "Done."
