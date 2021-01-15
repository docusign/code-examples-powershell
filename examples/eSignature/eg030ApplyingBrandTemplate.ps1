# https://developers.docusign.com/docs/esign-rest-api/how-to/apply-brand-and-template-to-envelope/

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$oAuthAccessToken = Get-Content .\config\ds_access_token.txt

#Set up variables for full code example
# Note: Substitute these values with your own
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$CC_EMAIL = $variables.CC_EMAIL
$CC_NAME = $variables.CC_NAME
$SIGNER_EMAIL = $variables.SIGNER_EMAIL
$SIGNER_NAME = $variables.SIGNER_NAME

# Check that we have a template id
if (Test-Path .\config\TEMPLATE_ID) {
    $templateID = Get-Content .\config\TEMPLATE_ID
}
else {
    Write-Output "A template id is needed. Fix: execute step 8 - Create Template"
    exit 1
}

# Check that we have a brand id
if (Test-Path .\config\BRAND_ID) {
    $brandId = Get-Content .\config\BRAND_ID
}
else {
    Write-Output "A brand id is needed. Fix: execute step 28 - Creating a brand"
    exit 1
}

# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

# Construct your request body
$body = @"
    {
        "templateId": "${templateID}",
        "brandId": "${brandId}",
        "templateRoles": [
            {
                "email": "${SIGNER_EMAIL}",
                "name": "${SIGNER_NAME}",
                "roleName": "signer"
            },
            {
                "email": "${CC_EMAIL}",
                "name": "${CC_NAME}",
                "roleName": "cc"
            }
        ],
        "status": "sent"
    }
"@

# a) Make a POST call to the createEnvelopes endpoint to create a new envelope.
# b) Display the JSON structure of the created envelope
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/envelopes"

try {
    Write-Output "Response:"
    $result = Invoke-WebRequest -uri $uri -headers $headers -body $body -method POST
    $result.content | ConvertFrom-Json | ConvertTo-Json
}
catch {
    $int = 0
    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}