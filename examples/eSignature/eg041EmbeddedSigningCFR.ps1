$apiUri = "https://demo.docusign.net/restapi"
$configPath = ".\config\settings.json"
$tokenPath = ".\config\ds_access_token.txt"
$accountIdPath = ".\config\API_ACCOUNT_ID"


# Check the folder structure to switch paths for Quick ACG
if ((Test-Path $configPath) -eq $false) {
    $configPath = "..\config\settings.json"
}
if ((Test-Path $tokenPath) -eq $false) {
    $tokenPath = "..\config\ds_access_token.txt"
}
if ((Test-Path $accountIdPath) -eq $false) {
    $accountIdPath = "..\config\API_ACCOUNT_ID"
}

# Use embedded signing

# Get required variables from .\config\settings.json file
$variables = Get-Content $configPath -Raw | ConvertFrom-Json
$SIGNER_EMAIL = $variables.SIGNER_EMAIL
$SIGNER_NAME = $variables.SIGNER_NAME
$PHONE_NUMBER = $variables.PHONE_NUMBER

# 1. Obtain your OAuth token
$oAuthAccessToken = Get-Content .\config\ds_access_token.txt

# Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountID = Get-Content $accountIdPath
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile
$doc1Base64 = New-TemporaryFile

$docPath = ".\demo_documents\World_Wide_Corp_lorem.pdf"

# Check the folder structure to switch paths for Quick ACG
if ((Test-Path $docPath) -eq $false) {
    $docPath = "..\demo_documents\World_Wide_Corp_lorem.pdf"
}

# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path $docPath))) > $doc1Base64
# - Obtain your workflow ID
# Step 2 start
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/identity_verification"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
Write-Output "Attempting to retrieve your account's workflow ID"

$result = Invoke-RestMethod -uri $uri -headers $headers -method GET
$result.content
#Obtain the workflow ID from the API response
$workflowId = [System.Linq.Enumerable]::FirstOrDefault($result.identityVerification, [func[object, bool]] { param($x) $x.defaultName -eq "SMS for Access & Signatures"}).workflowId
# Step 2 end

if ($null -eq $workflowId)
{
	throw "Please contact https://support.docusign.com to enable recipient phone authentication in your account."
}

Write-Output "Sending the envelope request to DocuSign..."

# Concatenate the different parts of the request
$SIGNER_COUNTRY_CODE = Read-Host "Please enter a country phone number prefix for the Signer"

$SIGNER_PHONE_NUMBER = Read-Host "Please enter an SMS-enabled Phone number for the Signer"
# Construct your envelope JSON body
# Step 3 start
$body = @"
{
	"documents": [{
		"documentBase64": "$(Get-Content $doc1Base64)",
		"documentId": "1",
		"fileExtension": "pdf",
		"name": "Lorem"
	}],
	"emailBlurb": "Please let us know if you have any questions.",
	"emailSubject": "Part 11 Example Consent Form",
	"envelopeIdStamping": "true",
	"recipients": {
		"signers": [{
			"name": "$SIGNER_NAME",
			"email": "$SIGNER_EMAIL",
			"roleName": "",
			"note": "",
			"routingOrder": 2,
			"clientUserID": 1000,
			"status": "created",
			"tabs": {
				"signHereTabs": [{
					"documentId": "1",
					"name": "SignHereTab",
					"pageNumber": "1",
					"recipientId": "1",
					"tabLabel": "SignHereTab",
					"xPosition": "200",
					"yPosition": "150"
				}]
			},
			"templateAccessCodeRequired": null,
			"deliveryMethod": "email",
			"recipientId": "1",
			"identityVerification":{
				"workflowId":"$workflowId",
				"steps":null,"inputOptions":[
					{"name":"phone_number_list",
					"valueType":"PhoneNumberList",
					"phoneNumberList":[
						{
							"countryCode":"$SIGNER_COUNTRY_CODE",
							"number":"$SIGNER_PHONE_NUMBER"
						}
						]
					}]
				}			
			}]
		},
	"status": "Sent"
}
"@ 
# Step 3 end
Write-Output ""

# Step 4. Call DocuSign to create the envelope
$uri = "${apiUri}/v2.1/accounts/$APIAccountId/envelopes"
$result = Invoke-WebRequest -uri $uri -headers $headers -body $body -method POST -UseBasicParsing -OutFile $response
$result.content

# pull out the envelopeId
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId

# Step 5. Create a recipient view definition
# The signer will directly open this link from the browser to sign.
#
# The returnUrl is normally your own web app. DocuSign will redirect
# the signer to returnUrl when the signing completes.
# For this example, we'll use http://httpbin.org/get to show the
# query parameters passed back from DocuSign

# temp files:
$requestData = New-TemporaryFile
$response = New-TemporaryFile

Write-Output "Requesting the url for the embedded signing..."

$json = [ordered]@{
    'returnUrl'            = 'http://httpbin.org/get';
    'authenticationMethod' = 'none';
    'email'                = $variables.SIGNER_EMAIL;
    'userName'             = $variables.SIGNER_NAME;
    'clientUserId'         = 1000
} | ConvertTo-Json -Compress


# Step 6. Create the recipient view and begin the DocuSign signing
Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/views/recipient" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $oAuthAccessToken";
    'Content-Type'  = "application/json";
} `
    -Body $json `
    -OutFile $response

Write-Output "Response: $(Get-Content -Raw $response)"
$signingUrl = $(Get-Content $response | ConvertFrom-Json).url

# ***DS.snippet.0.end
Write-Output "The embedded signing URL is $signingUrl"
Write-Output "It is only valid for five minutes. Attempting to automatically open your browser..."

Start-Process $signingUrl

# cleanup
Remove-Item $requestData
Remove-Item $response
Remove-Item $doc1Base64

Write-Output "Done."
