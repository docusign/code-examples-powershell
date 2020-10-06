$apiUri = "https://demo.docusign.net/restapi"

function Add-OemContent {
	param(
		$destination,
		$content
	)
	Add-Content -Path $destination -Value $content -Encoding oem -NoNewline
}

# Configuration
# 1.  Get required variables from .\config\settings.json:
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json
$CC_EMAIL = $variables.CC_EMAIL
$CC_NAME = $variables.CC_NAME
$SIGNER_EMAIL = $variables.SIGNER_EMAIL
$SIGNER_NAME = $variables.SIGNER_NAME

# 2. Obtain an OAuth access token from
#    https://developers.docusign.com/oauth-token-generator
$accessToken = Get-Content ([System.IO.Path]::Combine($PSScriptRoot, "..\config\ds_access_token.txt"))

# 3. Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
$accountId = Get-Content ([System.IO.Path]::Combine($PSScriptRoot, "..\config\API_ACCOUNT_ID"))

# ***DS.snippet.0.start
#  document 1 (html) has tag **signature_1**
#  document 2 (docx) has tag /sn1/
#  document 3 (pdf) has tag /sn1/
#
#  The envelope has two recipients.
#  recipient 1 - signer
#  recipient 2 - cc
#  The envelope will be sent first to the signer.
#  After it is signed, a copy is sent to the cc person.

# temp files
$requestData = New-TemporaryFile
$response = New-TemporaryFile

$doc1 = Get-Item ([System.IO.Path]::Combine($PSScriptRoot, "..\demo_documents\doc_1.html"))
$doc2 = Get-Item ([System.IO.Path]::Combine($PSScriptRoot, "..\demo_documents\World_Wide_Corp_Battle_Plan_Trafalgar.docx"))
$doc3 = Get-Item ([System.IO.Path]::Combine($PSScriptRoot, "..\demo_documents\World_Wide_Corp_lorem.pdf"))

Write-Output "Sending the envelope request to DocuSign..."
Write-Output "The envelope has three documents. Processing time will be about 15 seconds."
Write-Output "Results:"

# Step 1. Make the JSON part of the final request body
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

# Step 2. Assemble the multipart body
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

# Send request
try {
	Invoke-RestMethod `
		-Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
		-Method 'POST' `
		-Headers @{
		'Authorization' = "Bearer $accessToken";
		'Content-Type'  = "multipart/form-data; boundary=${boundary}";
	} `
		-InFile (Resolve-Path $requestData).Path `
		-OutFile $response

	Write-Output "Response: $(Get-Content -Raw $response)"
}
catch {
	Write-Error $_
}
# ***DS.snippet.0.end

Get-Content $response

# cleanup
Remove-Item $requestData
Remove-Item $response

Write-Output "Done."
