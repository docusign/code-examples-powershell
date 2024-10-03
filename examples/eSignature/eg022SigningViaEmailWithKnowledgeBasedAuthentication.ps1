# https://developers.docusign.com/docs/esign-rest-api/how-to/knowledge-based-authentication/

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

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
#ds-snippet-start:eSign22Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:eSign22Step2

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

# Construct your envelope JSON body
#ds-snippet-start:eSign22Step3
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
			"deliveryMethod": "Email",
			"name": "$SIGNER_NAME",
			"email": "$SIGNER_EMAIL",
			"idCheckConfigurationName": "ID Check $",
			"recipientId": "1",
			"requireIdLookup": "true",
			"routingOrder": "1",
			"status": "Created",
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
			}
		}]
	},
	"status": "Sent"
}
"@
#ds-snippet-end:eSign22Step3
Write-Output ""
Write-Output "Request: "
Write-Output $body

# a) Make a POST call to the createEnvelopes endpoint to create a new envelope.
# b) Display the JSON structure of the created envelope
#ds-snippet-start:eSign22Step4
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
#ds-snippet-end:eSign22Step4

# cleanup
Remove-Item $docBase64