# https://developers.docusign.com/docs/esign-rest-api/how-to/phone-auth/

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$SIGNER_EMAIL = $variables.SIGNER_EMAIL
$SIGNER_NAME = $variables.SIGNER_NAME
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
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

$SIGNER_NAME = Read-Host "Please enter name for the signer"

$SIGNER_EMAIL = Read-Host "Please enter email address for the signer"

$SIGNER_COUNTRY_CODE = Read-Host "Please enter a country code for recipient authentication for the signer"

$SIGNER_PHONE_NUMBER = Read-Host "Please enter a phone number for recipient authentication for the signer"
# Construct your envelope JSON body
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
					"xPosition": "75",
					"yPosition": "572"
				}]
			},
			"templateAccessCodeRequired": null,
			"deliveryMethod": "email",
			"recipientId": "1",
			"identityVerification":{
				"workflowId":"c368e411-1592-4001-a3df-dca94ac539ae",
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
Write-Output ""
Write-Output "Request: "
Write-Output $body

# a) Make a POST call to the createEnvelopes endpoint to create a new envelope.
# b) Display the JSON structure of the created envelope
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

# cleanup
Remove-Item $docBase64
