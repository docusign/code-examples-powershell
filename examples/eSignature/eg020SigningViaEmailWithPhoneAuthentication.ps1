# https://developers.docusign.com/docs/esign-rest-api/how-to/phone-auth/

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$PHONE_NUMBER = $variables.PHONE_NUMBER

# Get the envelope's custom field data
# This script uses the envelope ID stored in ../envelope_id.
# The envelope_id file is created by example eg016SetTabValues.ps1 or
# can be manually created.

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$oAuthAccessToken = Get-Content .\config\ds_access_token.txt

#Set up variables for full code example
# Note: Substitute these values with your own
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID


# temp files:
$docBase64 = New-TemporaryFile

# Fetch docs and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $docBase64

# Construct your API headers
#ds-snippet-start:eSign20Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:eSign20Step2

# - Obtain your workflow ID
#ds-snippet-start:eSign20Step3
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/identity_verification"

Write-Output "Attempting to retrieve your account's workflow ID"

Write-Output "Response:"
$result = Invoke-RestMethod -uri $uri -headers $headers -method GET
$result.content
#Obtain the workflow ID from the API response
$workflowId = [System.Linq.Enumerable]::FirstOrDefault($result.identityVerification, [func[object, bool]] { param($x) $x.defaultName -eq "Phone Authentication"}).workflowId
#ds-snippet-end:eSign20Step3

if ($null -eq $workflowId)
{
	throw "Please contact https://support.docusign.com to enable recipient phone authentication in your account."
}

$isDataIncorrect = $true
while($isDataIncorrect)
{
	$SIGNER_NAME = Read-Host "Please enter name for the signer"
	$SIGNER_EMAIL = Read-Host "Please enter email address for the signer"

	if ($SIGNER_EMAIL -eq $variables.SIGNER_EMAIL) {
		Write-Output ""
		Write-Output "For recipient authentication you must specify a different recipient from the account owner (sender) in order to ensure recipient authentication is performed."
		Write-Output ""
	} else {
		$isDataIncorrect = $false
	}
}

$SIGNER_COUNTRY_CODE = Read-Host "Please enter a country code for recipient authentication for the signer"
$SIGNER_PHONE_NUMBER = Read-Host "Please enter a phone number for recipient authentication for the signer"

# Construct your envelope JSON body
#ds-snippet-start:eSign20Step4
$body = @"
{
	"documents": [{
		"documentBase64": "$(Get-Content $docBase64)",
		"documentId": "1",
		"fileExtension": "pdf",
		"name": "Lorem"
	}],
	"emailBlurb": "Sample text for email body",
	"emailSubject": "Please Sign",
	"envelopeIdStamping": "true",
	"recipients": {
		"signers": [{
			"name": "$SIGNER_NAME",
			"email": "$SIGNER_EMAIL",
			"roleName": "",
			"note": "",
			"routingOrder": 2,
			"status": "created",
			"tabs": {
				"signHereTabs": [{
					"documentId": "1",
					"name": "SignHereTab",
					"pageNumber": "1",
					"recipientId": "1",
					"tabLabel": "SignHereTab",
					"xPosition": "200",
					"yPosition": "160"
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
#ds-snippet-end:eSign20Step4
Write-Output ""
Write-Output "Request: "
Write-Output $body

# a) Make a POST call to the createEnvelopes endpoint to create a new envelope.
# b) Display the JSON structure of the created envelope
#ds-snippet-start:eSign20Step5
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/envelopes"
try {
	Write-Output "Response:"
	$result = Invoke-WebRequest -uri $uri -headers $headers -body $body -method POST
	$result.content
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
#ds-snippet-end:eSign20Step5

# cleanup
Remove-Item $docBase64
