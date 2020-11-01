
#Step 1: Obtain your OAuth Token
# Note: These values are not valid, but are shown for example purposes only!
$AccessToken = 'eyJ0eXAi...Mzf5qp8mg'
$APIAccountId = "456cb790-xxxx-xxxx-xxxx-d77203b724fb"
$base_path = "https://demo.rooms.docusign.com"

#Step 2: Construct your API request headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization","Bearer $AccessToken")
$headers.add("Accept","application/json")
$headers.add("Content-Type","application/json")


###########################################################################################################
###########################################################################################################
#
# DEVDOCS-3432
#

# Step 3: Construct the request body
$body = @"
{ "name": "Sample Room Group" }
"@

# Step 4: a) Call the Rooms API
#         b) Display the JSON response    
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_groups"

try{
  write-host "Response:"
  $response = Invoke-WebRequest -uri $uri -headers $headers -method POST -body $body
  $response.Content
  $obj = $response.Content | ConvertFrom-Json 
  $formGroupID = $obj.formGroupId
  
}
catch{
  write-host "Unable to create a form group"
        # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

        foreach($header in $_.Exception.Response.Headers){
    	    if($header -eq "X-DocuSign-TraceToken"){ write-host "TraceToken : " $_.Exception.Response.Headers[$int]}
	            $int++
            }
   write-host "Error : "$_.ErrorDetails.Message
   write-host "Command : "$_.InvocationInfo.Line
}



###########################################################################################################

#
# DEVDOCS-3433
#


# Step 3: Get an office ID
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/offices"

try{
  write-host "Response:"
  $response = Invoke-WebRequest -uri $uri -headers $headers -method GET
  $response.Content
  # Retrieve the form group ID
  $obj = $response.Content | ConvertFrom-Json
  $officeID = $obj[0].officeSummaries.officeId

}
catch{
  write-host "Unable to retrieve an office ID"
        # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

        foreach($header in $_.Exception.Response.Headers){
    	    if($header -eq "X-DocuSign-TraceToken"){ write-host "TraceToken : " $_.Exception.Response.Headers[$int]}
	            $int++
            }
   write-host "Error : "$_.ErrorDetails.Message
   write-host "Command : "$_.InvocationInfo.Line
}

# Step 4. Call the Rooms API

$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_groups/$formGroupID/grant_office_access/$officeID"

try{
  $response = Invoke-WebRequest -uri $uri -headers $headers -method POST
  write-host $response.Status
  write-host "Response: No JSON response body returned when setting the default office ID in a form group"
}
catch{
  write-host "Unable to grant office access to form group"
        # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

        foreach($header in $_.Exception.Response.Headers){
    	    if($header -eq "X-DocuSign-TraceToken"){ write-host "TraceToken : " $_.Exception.Response.Headers[$int]}
	            $int++
            }
   write-host "Error : "$_.ErrorDetails.Message
   write-host "Command : "$_.InvocationInfo.Line
}

###########################################################################################################

#
# DEVDOCS-3434
#

# Step 3. Obtain the desired form ID
# Call the Rooms API to look up your forms library ID
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_libraries"
try{
  write-host "Response:"
  $response = Invoke-WebRequest -uri $uri -headers $headers -method GET
  $response.Content 
  # Retrieve a form library ID
  $obj = $response.Content | ConvertFrom-Json
  $formsLibraryID = $obj.formsLibrarySummaries[0].formsLibraryId
}
catch{
  write-host "Unable to retrieve form library"
        # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

        foreach($header in $_.Exception.Response.Headers){
    	    if($header -eq "X-DocuSign-TraceToken"){ write-host "TraceToken : " $_.Exception.Response.Headers[$int]}
	            $int++
            }
   write-host "Error : "$_.ErrorDetails.Message
   write-host "Command : "$_.InvocationInfo.Line
}


# Call the Rooms API to look up a list of form IDs for the given forms library
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_libraries/$formsLibraryID/forms"

try{
  write-host "Response:"
  $response = Invoke-WebRequest -uri $uri -headers $headers -method GET
  # Retrieve the the first form ID provided
  $response.Content
  $obj = $response | ConvertFrom-Json
  $formID = $obj.forms[0].libraryFormId
}
catch{
  write-host "Unable to retrieve a form id"
        # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

        foreach($header in $_.Exception.Response.Headers){
    	    if($header -eq "X-DocuSign-TraceToken"){ write-host "TraceToken : " $_.Exception.Response.Headers[$int]}
	            $int++
            }
   write-host "Error : "$_.ErrorDetails.Message
   write-host "Command : "$_.InvocationInfo.Line
}

# Step 4: Create your request body
$body =  
@"
 {"formId": "$formID" } 
"@

# Step 5: Call the Rooms API
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_groups/$formGroupID/assign_form"

try{
  $response = Invoke-WebRequest -uri $uri -headers $headers -method POST -Body $body
  write-host $response.Status
  write-host "Response: No JSON response body returned when setting the default office ID in a form group"
}
catch{
  write-host "Unable to assign the form to the form group"
        # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

        foreach($header in $_.Exception.Response.Headers){
    	    if($header -eq "X-DocuSign-TraceToken"){ write-host "TraceToken : " $_.Exception.Response.Headers[$int]}
	            $int++
            }
   write-host "Error : "$_.ErrorDetails.Message
   write-host "Command : "$_.InvocationInfo.Line
}


# Confirm that your form is attached to the Form Group
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_groups/$formGroupID"


try{
  write-host "Response: "
  $response = Invoke-WebRequest -uri $uri -headers $headers -method GET
  $response.Content
}
catch{
  write-host "Unable to retrieve a list of your available form groups"
        # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

        foreach($header in $_.Exception.Response.Headers){
    	    if($header -eq "X-DocuSign-TraceToken"){ write-host "TraceToken : " $_.Exception.Response.Headers[$int]}
	            $int++
            }
   write-host "Error : "$_.ErrorDetails.Message
   write-host "Command : "$_.InvocationInfo.Line
}