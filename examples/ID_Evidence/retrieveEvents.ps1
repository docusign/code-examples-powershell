# Required values: $oAuthAccessToken, $APIaccountId, $envelopeId
# Returns: $recipientIdGuid, $resourceToken, $copy_of_id_front

$oAuthAccessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Check that we have an IDV Envelope ID
if (-not (Test-Path .\config\IDV_ENVELOPE_ID)) {
    Write-Output "An IDV Envelope ID is needed. Run eSignature example 23 'Signing via Email with IDV Authentication' and complete IDV before running this code example."
    exit 0
}

$envelopeId = Get-Content .\config\IDV_ENVELOPE_ID

# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization","Bearer ${oAuthAccessToken}")
$headers.add("Accept","application/json, text/plain, */*")
$headers.add("Content-Type","application/json;charset=UTF-8")

# Retrieve recipient data
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/${APIaccountId}/envelopes/${envelopeId}/recipients"

write-host "Retrieving recipient data"

try{
	write-host "Response:"
	$result = Invoke-RestMethod -uri $uri -headers $headers -method GET
	$result.content
    #Obtain the recipient ID GUID from the API response
	$recipientIdGuid = $result.signers.recipientIdGuid
	}
catch{
	$int = 0
	foreach($header in $_.Exception.Response.Headers){
	#On error, display the error, the line that triggered the error, and the TraceToken
		if($header -eq "X-DocuSign-TraceToken"){ write-host "TraceToken : " $_.Exception.Response.Headers[$int]}
		$int++
	}
	write-host "Error : "$_.ErrorDetails.Message
	write-host "Command : "$_.InvocationInfo.Line
} 

write-host "recipientIdGuid: " $recipientIdGuid
# Save the Recipient ID Guid for use by other scripts
Write-Output $recipientIdGuid > .\config\RECIPIENT_ID_GUID


# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization","Bearer ${oAuthAccessToken}")
$headers.add("Accept","application/json, text/plain, */*")
$headers.add("Content-Type","application/json;charset=UTF-8")

# Obtain identity proof token (resource token)
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/${APIaccountId}/envelopes/${envelopeId}/recipients/${recipientIdGuid}/identity_proof_token"

write-host "Attempting to retrieve your identity proof token"

try{
	write-host "Response:"
	$result = Invoke-RestMethod -uri $uri -headers $headers -method POST
	$result.content
    #Obtain the resourceToken from the API response
	$resourceToken = $result.resourceToken
	}
catch{
	$int = 0
	foreach($header in $_.Exception.Response.Headers){
	#On error, display the error, the line that triggered the error, and the TraceToken
		if($header -eq "X-DocuSign-TraceToken"){ write-host "TraceToken : " $_.Exception.Response.Headers[$int]}
		$int++
	}
	write-host "Error : "$_.ErrorDetails.Message
	write-host "Command : "$_.InvocationInfo.Line
} 

write-host "resourceToken: " $resourceToken
# Save the Resource Token for use by other scripts
Write-Output $resourceToken > .\config\RESOURCE_TOKEN.txt


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization","Bearer $resourceToken")
$headers.add("Accept","application/json, text/plain, */*")
$headers.add("Content-Type","application/json;charset=UTF-8")

# Retrieve recipient data
$uri = "https://proof-d.docusign.net/api/v1/events/person/$recipientIdGuid.json"

write-host "Retrieving recipient data"

try{
	write-host "Response:"
	$result = Invoke-RestMethod -uri $uri -headers $headers -UseBasicParsing -method GET
    #Obtain the Event List from the API response
	$EventList = $result.events | ConvertTo-Json 

	write-host $EventList
	}
catch{
	$int = 0
	foreach($header in $_.Exception.Response.Headers){
	#On error, display the error, the line that triggered the error, and the TraceToken
		if($header -eq "X-DocuSign-TraceToken"){ write-host "TraceToken : " $_.Exception.Response.Headers[$int]}
		$int++
	}
	write-host "Error : "$_.ErrorDetails.Message
	write-host "Command : "$_.InvocationInfo.Line
} 

$copy_of_id_front = $result.events.data.copy_of_id_front  | ConvertTo-Json 
write-host "copy_of_id_front:"$copy_of_id_front
# Save the copy_of_id_front URL for use by other scripts
Write-Output $copy_of_id_front > .\config\COPY_OF_ID_FRONT_URL.txt

# cleanup
