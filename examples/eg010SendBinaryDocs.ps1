$apiUri = "https://demo.docusign.net/restapi"

# function AppendFile {
# 	param(
# 		$source,
# 		$destination
# 	)
# 	$destinationStream = $destination.OpenWrite()
# 	$destinationStream.Seek(0, [System.IO.SeekOrigin]::End)
# 	$sourceStream = $source.OpenRead()
# 	$sourceStream.CopyTo($destinationStream)
# 	$destinationStream.Flush()
# 	$destinationStream.Dispose()
# 	$sourceStream.Dispose()
# }
# Add-Content -Path $tmp  -Value "hello!" -Encoding ascii -NoNewline

function Add-AsciiContent {
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
$PSDefaultParameterValues['Out-File:Encoding'] = 'ascii'
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
Add-AsciiContent $requestData "--$boundary"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "Content-Type: application/json"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "Content-Disposition: form-data"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData $json
Add-AsciiContent $requestData "${CRLF}"

# Next add the documents. Each document has its own mime type,
# filename, and documentId. The filename and documentId must match
# the document's info in the JSON.
Add-AsciiContent $requestData "--$boundary"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "Content-Type: text/html"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "Content-Disposition: file; filename=`"Order acknowledgement`";documentid=1"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "${CRLF}"
#(Get-Content $doc1) 
#AppendFile $doc1 $requestData
Add-AsciiContent $requestData (Get-Content $doc1 -Encoding ascii) #$doc1
Add-AsciiContent $requestData "${CRLF}"

Add-AsciiContent $requestData "--$boundary"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "Content-Type: application/vnd.openxmlformats-officedocument.wordprocessingml.document"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "Content-Disposition: file; filename=`"Battle Plan`";documentid=2"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "${CRLF}"
#(Get-Content $doc2) 
#AppendFile $doc2 $requestData
#Add-AsciiContent $requestData (Get-Content $doc2 -Encoding ascii)#$doc2
Add-Content $requestData (Get-Content $doc2 -Encoding oem -Raw) -Encoding oem -NoNewline
Add-AsciiContent $requestData "${CRLF}"

Add-AsciiContent $requestData "--$boundary"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "Content-Type: application/pdf"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "Content-Disposition: file; filename=`"Lorem Ipsum`";documentid=3"
Add-AsciiContent $requestData "${CRLF}"
Add-AsciiContent $requestData "${CRLF}"
#(Get-Content $doc3) 
#AppendFile $doc3 $requestData
Add-Content $requestData (Get-Content $doc3 -Encoding oem -Raw) -Encoding oem -NoNewline
Add-AsciiContent $requestData "${CRLF}"

# Add closing boundary
Add-AsciiContent $requestData "--$boundary--"  
Add-AsciiContent $requestData "${CRLF}"

Copy-Item  $requestData "d:\req" -Force

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
#Remove-Item $requestData
Remove-Item $response

Write-Output "Done."
