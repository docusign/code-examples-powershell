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


# Required values: $resourceToken, $copy_of_id_front

# Check that we have Copy of ID front URL and Resource Token in config file
#if ((-not (Test-Path .\config\COPY_OF_ID_FRONT_URL.txt)) -or (-not (Test-Path .\config\RESOURCE_TOKEN.txt))) {
#    Write-Output "Copy of ID Front URL and Resource Token are needed. Run ID Evidence example 1 'Retrieve events' before running this code example."
#    exit -1
#}
$copy_of_id_front = Get-Content .\config\COPY_OF_ID_FRONT_URL.txt
#$recipientIdGuid = Get-Content .\config\RECIPIENT_ID_GUID
$resourceToken = Get-Content .\config\RESOURCE_TOKEN.txt


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization","Bearer $resourceToken")
$headers.add("Accept", "image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, */*")
$headers.add("Content-Type","image/jpg")

# return a base-64 image of the front of the photo ID
#$uri = "https://proof-d.docusign.net/api/v1/events/person/${recipientIdGuid}/${eventId}/media/${frontMediaId}"
$uri = "https://proof-d.docusign.net/api/v1/events/person/eecbf35c-753d-4b72-9780-9fe993fe6b6c/2e914d89-b174-4598-9422-53328cb92170/media/e6b45fc9-04e9-42ea-be94-f7a939d5dbc9"
#$uri = 
#$uri = $copy_of_id_front

#[system.uri]$copy_of_id_front = $uri
#[uri]::IsWellFormedUriString($copy_of_id_front, 'Absolute')
#[uri]::IsWellFormedUriString($uri, 'Absolute')

write-host "Retrieving recipient data"

try{
	#Obtain the base-64 image
	$result = Invoke-RestMethod -uri $uri -headers $headers -method GET
	#$result.content
	$result > C:\id_front_base64_image.txt
	write-host "Response: Saved to C:\id_front_base64_image.txt"
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

# cleanup
