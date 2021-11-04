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


# temp files:
$docBase64 = New-TemporaryFile

# Fetch docs and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $docBase64

# - Construct your API headers
# Step 2 start
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json, text/plain, */*")
$headers.add("Content-Type", "application/json;charset=UTF-8")
$headers.add("Accept-Encoding", "gzip, deflate, br")
$headers.add("Accept-Language", "en-US,en;q=0.9")
# Step 2 end

# - Obtain your workflow ID
# Step 3 start
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/identity_verification"

Write-Output "Attempting to retrieve your account's workflow ID"

Write-Output "Response:"
$result = Invoke-RestMethod -uri $uri -headers $headers -method GET
$result.content
#Obtain the workflow ID from the API response
$workflowId = [System.Linq.Enumerable]::FirstOrDefault($result.identityVerification, [func[object, bool]] { param($x) $x.defaultName -eq "DocuSign ID Verification"}).workflowId
# Step 3 end

# - Construct your envelope JSON body
# Note: If you did not successfully obtain your workflow ID, this step will fail.
# Step 4 start
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
						"recipientId":"1",
						"tabLabel": "SignHereTab",
						"xPosition": "200",
						"yPosition": "160"
					}]
				},
			"templateAccessCodeRequired": null,
			"deliveryMethod": "email",
			"recipientId": "1",
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
# Step 4 end
Write-Output ""
Write-Output "Request: "
Write-Output $body

# a) Make a POST call to the createEnvelopes endpoint to create a new envelope.
# b) Display the JSON structure of the created envelope
# Step 5 start
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
# Step 5 end

# cleanup
Remove-Item $docBase64