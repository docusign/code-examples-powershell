# https://developers.docusign.com/docs/esign-rest-api/how-to/id-verification/

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$SIGNER_EMAIL = $variables.SIGNER_EMAIL
$SIGNER_NAME = $variables.SIGNER_NAME

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

# Check that we have an envelope id
if (Test-Path .\config\ENVELOPE_ID) {
	$envelopeID = Get-Content .\config\ENVELOPE_ID
}
else {
	Write-Output "PROBLEM: An envelope id is needed. Fix: execute step 2 - Signing_Via_Email"
	exit 1
}

# temp files:
$docBase64 = New-TemporaryFile

# Fetch docs and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $docBase64

# - Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json, text/plain, */*")
$headers.add("Content-Type", "application/json;charset=UTF-8")
$headers.add("Accept-Encoding", "gzip, deflate, br")
$headers.add("Accept-Language", "en-US,en;q=0.9")

# - Obtain your workflow ID
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/identity_verification"

Write-Output "Attempting to retrieve your account's workflow ID"

try {
	Write-Output "Response:"
	$result = Invoke-RestMethod -uri $uri -headers $headers -method GET
	$result.content
	#Obtain the workflow ID from the API response
	$workflowId = $result.identityVerification.workflowId
}
catch {
	$int = 0
	foreach ($header in $_.Exception.Response.Headers) {
		#On error, display the error, the line that triggered the error, and the TraceToken
		if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
		$int++
	}
	Write-Output "Error : "$_.ErrorDetails.Message
	Write-Output "Command : "$_.InvocationInfo.Line
}

# - Construct your envelope JSON body
# Note: If you did not successfully obtain your workflow ID, this step will fail.
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
			"routingOrder": 1,
			"status": "created",
			"tabs": {
					"signHereTabs": [{
						"documentId": "1",
						"name": "SignHereTab",
						"pageNumber": "1",
						"recipientId": "$envelopeID",
						"tabLabel": "SignHereTab",
						"xPosition": "75",
						"yPosition": "572"
					}]
				},
			"templateAccessCodeRequired": null,
			"deliveryMethod": "email",
			"recipientId": "$envelopeID",
			"identityVerification": {
				"workflowId": "$workflowId",
				"steps": null
			},
		"idCheckConfigurationName": "",
		"requireIdLookup": false
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