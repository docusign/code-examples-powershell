# https://developers.docusign.com/docs/esign-rest-api/how-to/bulk-send-envelopes/

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$oAuthAccessToken = Get-Content .\config\ds_access_token.txt

#Set up variables for full code example
# Note: Substitute these values with your own
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$SIGNER1_EMAIL = Read-Host "Please enter Bulk copy #1 signer email address"
$SIGNER1_NAME = Read-Host "Please enter Bulk copy #1 signer name"
$CC1_EMAIL = Read-Host "Please enter Bulk copy #1 carbon copy email address"
$CC1_NAME = Read-Host "Please enter Bulk copy #1 carbon copy name"
$SIGNER2_EMAIL = Read-Host "Please enter Bulk copy #2 signer email address"
$SIGNER2_NAME = Read-Host "Please enter Bulk copy #2 signer name"
$CC2_EMAIL = Read-Host "Please enter Bulk copy #2 carbon copy email address"
$CC2_NAME = Read-Host "Please enter Bulk copy #2 carbon copy name"

$doc1Base64 = New-TemporaryFile
# Fetch doc and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\World_Wide_Corp_lorem.pdf"))) > $doc1Base64

# Step 2 start
# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json, text/plain, */*")
$headers.add("Content-Type", "application/json;charset=UTF-8")
$headers.add("Accept-Encoding", "gzip, deflate, br")
$headers.add("Accept-Language", "en-US,en;q=0.9")
# Step 2 end

$continue = $true

# Step 3 start
# Step 3. Submit a bulk list
# Submit the Bulk List
# Create a temporary file to store the JSON body
# The JSON body must contain the recipient role, recipientId, name, and email.
$body = @"
{
	"name": "sample.csv",
	"bulkCopies": [{
		"recipients": [{
			"roleName": "signer",
			"name": "${SIGNER1_NAME}",
			"email": "${SIGNER1_EMAIL}"
		},
		{
			"roleName": "cc",
			"name": "${CC1_NAME}",
			"email": "${CC1_EMAIL}"
		}],
		"customFields": []
	},
{
		"recipients": [{
			"roleName": "signer",
			"name": "${SIGNER2_NAME}",
			"email": "${SIGNER2_EMAIL}"
		},
		{
			"roleName": "cc",
			"name": "${CC2_NAME}",
			"email": "${CC2_EMAIL}"
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
# Step 3 end
# Step 4 start
# Step 4. Create an envelope
# Create your draft envelope
$body = @"
{
	"documents": [{
		"documentBase64": "$(Get-Content $doc1Base64)",
		"documentId": "1",
		"fileExtension": "txt",
		"name": "NDA"
	}],
	"envelopeIdStamping": "true",
	"emailSubject": "Please sign",
	"recipients": {
		"signers": [{
			"name": "Multi Bulk Recipient::signer",
			"email": "multiBulkRecipients-signer@docusign.com",
			"roleName": "signer",
			"routingOrder": "1",
			"recipientId" : "1",
			"recipientType" : "signer",
			"delieveryMethod" : "Email",
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
				}]}
			}],
		"carbonCopies": [{
			"name": "Multi Bulk Recipient::cc",
			"email": "multiBulkRecipients-cc@docusign.com",
			"roleName": "cc",
			"routingOrder": "2",
			"recipientId" : "2",
			"recipientType" : "cc",
			"delieveryMethod" : "Email",
			"status": "created"
			}]
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
# Step 4 end
# Step 5 start
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
# Step 5 start
# Step 5 end
# Step 6. Initiate bulk send
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
# Step 6 end
# Step 7 start
# Step 7. Confirm successful batch send
# Confirm successful batch send
# Note: Depending on the number of Bulk Recipients, it may take some time for the Bulk Send to complete. For 2000 recipients this can take ~1 hour.
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/bulk_send_batch/$bulkBatchId"
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
# Step 7 end
