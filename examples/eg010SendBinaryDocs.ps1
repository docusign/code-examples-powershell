# Configuration
# 1. Search for and update '{USER_EMAIL}' and '{USER_FULLNAME}'.
#    They occur and re-occur multiple times below.
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

$basePath = "https://demo.docusign.net/restapi"

# Get environment variables
$CC_EMAIL = $(Get-Variable CC_EMAIL -ValueOnly) -replace '["]'
$CC_NAME = $(Get-Variable CC_NAME -ValueOnly) -replace '["]'
$SIGNER_EMAIL = $(Get-Variable SIGNER_EMAIL -ValueOnly) -replace '["]'
$SIGNER_NAME = $(Get-Variable SIGNER_NAME -ValueOnly) -replace '["]'

# temp files
$PSDefaultParameterValues['Out-File:Encoding'] = 'ascii'
$requestData = New-TemporaryFile
$response = New-TemporaryFile

$doc1 = Get-Item ([System.IO.Path]::Combine($PSScriptRoot, "..\demo_documents\doc_1.html"))
$doc2 = Get-Item ([System.IO.Path]::Combine($PSScriptRoot, "..\demo_documents\World_Wide_Corp_Battle_Plan_Trafalgar.docx"))
$doc3 = Get-Item ([System.IO.Path]::Combine($PSScriptRoot, "..\demo_documents\World_Wide_Corp_lorem.pdf"))

Write-Output "`nSending the envelope request to DocuSign..."
Write-Output "The envelope has three documents. Processing time will be about 15 seconds."
Write-Output "Results:`n"

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
} | ConvertTo-Json -Depth 32;

# Step 2. Assemble the multipart body
$CRLF = "`r`n"
$boundary = "multipartboundary_multipartboundary"
"--$boundary" > $requestData
"Content-Type: application/json" >> $requestData
"Content-Disposition: form-data" >> $requestData
"${CRLF}" >> $requestData
"$json" >> $requestData

# Next add the documents. Each document has its own mime type,
# filename, and documentId. The filename and documentId must match
# the document's info in the JSON.
"--$boundary"  >> $requestData
"Content-Type: text/html"  >> $requestData
"Content-Disposition: file; filename=`"Order acknowledgement`";documentid=1" >> $requestData
"${CRLF}" >> $requestData
(Get-Content $doc1) >> $requestData

"--$boundary"  >> $requestData
"Content-Type: application/vnd.openxmlformats-officedocument.wordprocessingml.document"  >> $requestData
"Content-Disposition: file; filename=`"Battle Plan`";documentid=2" >> $requestData
"${CRLF}" >> $requestData
(Get-Content $doc2) >> $requestData

"--$boundary" >> $requestData
"Content-Type: application/pdf"  >> $requestData
"Content-Disposition: file; filename=`"Lorem Ipsum`";documentid=3" >> $requestData
"${CRLF}" >> $requestData
(Get-Content $doc3) >> $requestData

# Add closing boundary
"--$boundary--"  >> $requestData

# Send request
try {
	Invoke-RestMethod `
		-Uri "${basePath}/v2.1/accounts/${accountId}/envelopes" `
		-Method 'POST' `
		-Headers @{
		'Authorization' = "Bearer $accessToken";
		'Content-Type'  = "multipart/form-data; boundary=${boundary}";
	} `
		-InFile (Resolve-Path $requestData).Path `
		-OutFile $response

	Write-Output "Response: $(Get-Content -Raw $response)`n"
}
catch {
	Write-Error $_
}
# ***DS.snippet.0.end

Write-Output ""
Get-Content $response

# cleanup
Remove-Item $requestData
Remove-Item $response

Write-Output ""
Write-Output ""
Write-Output "Done."
Write-Output ""
