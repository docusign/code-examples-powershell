#ds-snippet-start:eSign10Step3
function Add-OemContent {
	param(
		$destination,
		$content
	)
	Add-Content -Path $destination -Value $content -Encoding oem -NoNewline
}
#ds-snippet-end:eSign10Step3

# Configuration
# Get required variables from .\config\settings.json:
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$CC_EMAIL = $variables.CC_EMAIL
$CC_NAME = $variables.CC_NAME
$SIGNER_EMAIL = $variables.SIGNER_EMAIL
$SIGNER_NAME = $variables.SIGNER_NAME
# Obtain your OAuth access token
$accessToken = Get-Content ".\config\ds_access_token.txt"

# Obtain your accountId from demo.docusign.net -- the account id is shown in
# the drop down on the upper right corner of the screen by your picture or
# the default picture.
$accountId = Get-Content ".\config\API_ACCOUNT_ID"

#ds-snippet-start:eSign10Step3
# Construct the request body
#  document 1 (html) has tag **signature_1**
#  document 2 (docx) has tag /sn1/
#  document 3 (pdf) has tag /sn1/
#
#  The envelope has two recipients.
#  recipient 1 - signer
#  recipient 2 - cc
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.

$apiUri = "https://demo.docusign.net/restapi"

# temp files
$requestData = New-TemporaryFile
$response = New-TemporaryFile

$doc1 = Get-Item ".\demo_documents\doc_1.html"
$doc2 = Get-Item ".\demo_documents\World_Wide_Corp_Battle_Plan_Trafalgar.docx"
$doc3 = Get-Item ".\demo_documents\World_Wide_Corp_lorem.pdf"

Write-Output "Sending the envelope request to Docusign..."
Write-Output "The envelope has three documents. Processing time will be about 15 seconds."
Write-Output "Results:"

$json = @{
	emailSubject = "Please sign this document set";
	documents    = @(@{
			name          = "Order acknowledgement";
			fileExtension = "html";
			documentId    = "1";
		}; @{
			name          = "Battle Plan";
			fileExtension = "docx";
			documentId    = "2";
		}; @{
			name          = "Lorem Ipsum";
			fileExtension = "pdf";
			documentId    = "3";
		});
	recipients   = @{
		signers      = @(@{
				email        = $SIGNER_EMAIL;
				name         = $SIGNER_NAME;
				recipientId  = "1";
				routingOrder = "1";
				tabs         = @{
					signHereTabs = @(@{
							anchorString  = "**signature_1**";
							anchorYOffset = "10";
							anchorUnits   = "pixels";
							anchorXOffset = "20";
						}; @{
							anchorString  = "/sn1/";
							anchorYOffset = "10";
							anchorUnits   = "pixels";
							anchorXOffset = "20";
						})
				}
			});
		carbonCopies = @(@{
				email        = $CC_EMAIL;
				name         = $CC_NAME;
				routingOrder = 2;
				recipientId  = 2;
			})
	};
	status       = "sent"
} | ConvertTo-Json -Depth 32 -Compress;

$CRLF = "`r`n"
$boundary = "multipartboundary_multipartboundary"
Add-OemContent $requestData "--$boundary"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "Content-Type: application/json"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "Content-Disposition: form-data"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData $json
Add-OemContent $requestData "${CRLF}"

# Next add the documents. Each document has its own mime type,
# filename, and documentId. The filename and documentId must match
# the document's info in the JSON.
Add-OemContent $requestData "--$boundary"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "Content-Type: text/html"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "Content-Disposition: file; filename=`"Order acknowledgement`";documentid=1"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData (Get-Content $doc1 -Encoding oem)
Add-OemContent $requestData "${CRLF}"

Add-OemContent $requestData "--$boundary"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "Content-Type: application/vnd.openxmlformats-officedocument.wordprocessingml.document"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "Content-Disposition: file; filename=`"Battle Plan`";documentid=2"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData (Get-Content $doc2 -Encoding oem -Raw)
Add-OemContent $requestData "${CRLF}"

Add-OemContent $requestData "--$boundary"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "Content-Type: application/pdf"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "Content-Disposition: file; filename=`"Lorem Ipsum`";documentid=3"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData "${CRLF}"
Add-OemContent $requestData (Get-Content $doc3 -Encoding oem -Raw)
Add-OemContent $requestData "${CRLF}"

# Add closing boundary
Add-OemContent $requestData "--$boundary--"
Add-OemContent $requestData "${CRLF}"
#ds-snippet-end:eSign10Step3

#ds-snippet-start:eSign10Step2
$headers = @{
	'Authorization' = "Bearer $accessToken";
	'Content-Type'  = "multipart/form-data; boundary=${boundary}";
}
#ds-snippet-end:eSign10Step2

# Send request
try {
	# Call the eSignature REST API
	#ds-snippet-start:eSign10Step4
	Invoke-RestMethod `
		-Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
		-Method 'POST' `
		-Headers $headers `
		-InFile (Resolve-Path $requestData).Path `
		-OutFile $response

	Write-Output "Response: $(Get-Content -Raw $response)"
	#ds-snippet-end:eSign10Step4
}
catch {
	Write-Error $_
}

Get-Content $response

# cleanup
Remove-Item $requestData
Remove-Item $response

Write-Output "Done."
