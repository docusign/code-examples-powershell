# https://developers.docusign.com/docs/esign-rest-api/how-to/apply-brand-to-envelope/

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$oAuthAccessToken = Get-Content .\config\ds_access_token.txt

#Set up variables for full code example
# Note: Substitute these values with your own
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$SIGNER_EMAIL = $variables.SIGNER_EMAIL
$SIGNER_NAME = $variables.SIGNER_NAME

# Check that we have a brand id
if (Test-Path .\config\BRAND_ID) {
	$brandID = Get-Content .\config\BRAND_ID
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
	"documents": [{
		"documentBase64": "DQoNCg0KCQkJCXRleHQgZG9jDQoNCg0KDQoNCg0KUk0gIwlSTSAjCVJNICMNCg0KDQoNClxzMVwNCg0KLy9hbmNoMSANCgkvL2FuY2gyDQoJCS8vYW5jaDM=",
		"documentId": "1",
		"fileExtension": "txt",
		"name": "NDA"
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
					"recipientId": "1",
					"tabLabel": "SignHereTab",
					"xPosition": "75",
					"yPosition": "572"
				}]
			},
		"deliveryMethod": "email",
		"recipientId": "1",
	}]
	},
"brandId": "${brandID}",
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