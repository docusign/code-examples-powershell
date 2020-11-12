# https://developers.docusign.com/docs/esign-rest-api/how-to/bulk-send-envelopes/

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

# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json, text/plain, */*")
$headers.add("Content-Type", "application/json;charset=UTF-8")
$headers.add("Accept-Encoding", "gzip, deflate, br")
$headers.add("Accept-Language", "en-US,en;q=0.9")

$continue = $true

# Step 3. Submit a bulk list
# Submit the Bulk List
# Create a temporary file to store the JSON body
# The JSON body must contain the recipient role, recipientId, name, and email.
$body = @"
{
	"name": "sample.csv",
	"bulkCopies": [{
		"recipients": [{
			"recipientId": "39542944",
			"role": "signer",
			"tabs": [],
			"name": "${SIGNER_NAME}",
			"email": "${SIGNER_EMAIL}"
		},
		{
			"recipientId": "84754526",
			"role": "cc",
			"tabs": [],
			"name": "${CC_NAME}",
			"email": "${CC_EMAIL}"
		}],
		"customFields": []
	},
{
		"recipients": [{
			"recipientId": "39542944",
			"role": "signer",
			"tabs": [],
			"name": "${SIGNER_NAME}",
			"email": "${SIGNER_EMAIL}"
		},
		{
			"recipientId": "84754526",
			"role": "cc",
			"tabs": [],
			"name": "${CC_NAME}",
			"email": "${CC_EMAIL}"
		}],
		"customFields": []
	}]
}
"@

$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/bulk_send_lists"

# Make a POST call to the bulk_send_lists endpoint, this will be referenced in future API calls.
# Display the JSON structure of the API response
# Create a temporary file to store the response
try {
	Write-Output @"

        Posting bulk send list
"@
	$response = Invoke-RestMethod -uri $uri -headers $headers -body $body -method POST
	#Obtain the listId from the response
	$listId = $response.listId
	$response.bulkCopies | ConvertTo-Json
}
catch {
	#On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
	Write-Output "Posting of your Bulk List has failed"
	$continue = $false
	$int = 0
	foreach ($header in $_.Exception.Response.Headers) {
		if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
		$int++
	}
	Write-Output "Error : "$_.ErrorDetails.Message
	Write-Output "Command : "$_.InvocationInfo.Line
}

# Step 4. Create an envelope
# Create your draft envelope
$base = "DQoNCg0KCQkJCXRleHQgZG9jDQoNCg0KDQoNCg0KUk0gIwlSTSAjCVJNICMNCg0KDQoNClxzMVwNCg0KLy9hbmNoMSANCgkvL2FuY2gyDQoJCS8vYW5jaDM="
$body = @"
{
	"documents": [{
		"documentBase64": "$base",
		"documentId": "1",
		"fileExtension": "txt",
		"name": "NDA"
	}],
	"envelopeIdStamping": "true",
	"emailSubject": "Please sign",
	"cdse_mode": "true",
	"recipients": {
	},
	"status": "created"
}
"@

$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/envelopes"
$response = $null
if ($continue -eq $true) {
	try {
		Write-Output @"

        Creating a Draft Envelope
"@
		$response = Invoke-RestMethod -uri $uri -method post -headers $headers -body $body
		$response | ConvertTo-Json
		#Obtain the envelopeId from the API response.
		$envelopeId = $response.envelopeId
	}
	catch {
		Write-Output "Envelope creation failed"
		#On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
		$continue = $false
		$int = 0
		foreach ($header in $_.Exception.Response.Headers) {
			if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
			$int++
		}
		Write-Output "Error : "$_.ErrorDetails.Message
		Write-Output "Command : "$_.InvocationInfo.Line
	}
}

# Step 5. Attach your bulk list ID to the envelope
# Add an envelope custom field set to the value of your listId
# This Custom Field is used for tracking your Bulk Send via the Envelopes::Get method
# Create a temporary file to store the JSON body
$body = @"
{
	"listCustomFields": [],
	"textCustomFields": [{
		"name": "mailingListId",
		"required": false,
		"show": false,
		"value": "${listId}"
	}]
}
"@

$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/envelopes/$envelopeId/custom_fields"
try {
	Write-Output @"

        Adding the ListId as an Envelope Custom Field
"@
	$response = Invoke-RestMethod -uri $uri -headers $headers -body $body -method POST
	$response | ConvertTo-Json
}
catch {
	Write-Output "Adding envelope custom field has failed"
	# On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
	$continue = $false
	$int = 0
	foreach ($header in $_.Exception.Response.Headers) {
		if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
		$int++
	}
	Write-Output "Error : "$_.ErrorDetails.Message
	Write-Output "Command : "$_.InvocationInfo.Line
}

# Step 6. Add placeholder recipients
# Add placeholder recipients.
# Note: The name / email format used is:
#		Name: Multi Bulk Recipients::{rolename}
#		Email: MultiBulkRecipients-{rolename}@docusign.com
$body = @"
{
	"signers": [{
		"name": "Multi Bulk Recipient::cc",
		"email": "multiBulkRecipients-cc@docusign.com",
		"roleName": "cc",
		"routingOrder": 1,
		"status": "created",
		"templateAccessCodeRequired": null,
		"deliveryMethod": "email",
		"recipientId": "84754526",
		"recipientType": "signer"
	},
	{
		"name": "Multi Bulk Recipient::signer",
		"email": "multiBulkRecipients-signer@docusign.com",
		"roleName": "signer",
		"routingOrder": 1,
		"status": "created",
		"templateAccessCodeRequired": null,
		"deliveryMethod": "email",
		"recipientId": "39542944",
		"recipientType": "signer"
	}]
}
"@

$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/envelopes/$envelopeId/recipients"

if ($continue -eq $true) {
	try {
		Write-Output @"

        Adding placeholder recipients to the envelope
"@
		$response = Invoke-RestMethod -uri $uri -headers $headers -body $body -method POST
		$response | ConvertTo-Json
	}
	catch {
		Write-Output "Adding placeholder recipients has failed"
		#On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error        #On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
		$continue = $false
		$int = 0
		foreach ($header in $_.Exception.Response.Headers) {
			if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
			$int++
		}
		Write-Output "Error : "$_.ErrorDetails.Message
		Write-Output "Command : "$_.InvocationInfo.Line
	}
}

# Step 7. Initiate bulk send
# Initiate the Bulk Send
# Target endpoint: {ACCOUNT_ID}/bulk_send_lists/{LIST_ID}/send
$body = @"
{
	"listId": "${listId}",
	"envelopeOrTemplateId": "${envelopeId}",
}
"@

$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/bulk_send_lists/$listId/send"
if ($continue -eq $true) {
	try {
		Write-Output @"

    Initiating Bulk Send
"@
		$response = Invoke-RestMethod -uri $uri -headers $headers -body $body -method POST
		$bulkBatchId = $response.batchId
		$response | ConvertTo-Json
	}
	catch {
		Write-Output "Envelope send failed"
		# On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
		$continue = $false
		$int = 0
		foreach ($header in $_.Exception.Response.Headers) {
			if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
			$int++
		}
		Write-Output "Error : "$_.ErrorDetails.Message
		Write-Output "Command : "$_.InvocationInfo.Line
	}
}

# Step 8. Confirm successful batch send
# Confirm successful batch send
# Note: Depending on the number of Bulk Recipients, it may take some time for the Bulk Send to complete. For 2000 recipients this can take ~1 hour.
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/bulk_envelopes/$bulkBatchId"

if ($continue -eq $true) {
	$response = $null
	try {
		Write-Output @"

        Retrieving Bulk Send status
"@
		Start-Sleep -Second 10
		$response = Invoke-RestMethod -uri $uri -headers $headers -method GET
		$response | ConvertTo-Json
	}
	catch {
		Write-Output "Unable to retrieve Bulk Status."
		# On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
		foreach ($header in $_.Exception.Response.Headers) {
			if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
			$int++
		}
		Write-Output "Error : "$_.ErrorDetails.Message
		Write-Output "Command : "$_.InvocationInfo.Line
	}
}
