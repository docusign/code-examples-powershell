# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

# Get form group ID from the .\config\FORM_GROUP_ID file
if (Test-Path .\config\FORM_GROUP_ID) {
    $formGroupID = Get-Content .\config\FORM_GROUP_ID
}
else {
    Write-Output "A form group ID is needed. Fix: execute step 7 - Create a form group..."
    exit 1
}

# Call the Rooms API to look up your forms library ID
$base_path = "https://demo.rooms.docusign.com"
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_libraries"
try {
    Write-Output "Response:"
    $response = Invoke-WebRequest -uri $uri -headers $headers -method GET
    $response.Content
    # Retrieve a form library ID
    $obj = $response.Content | ConvertFrom-Json
    $formsLibraryID = $obj.formsLibrarySummaries[0].formsLibraryId
}
catch {
    Write-Output "Unable to retrieve form library"
    # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}

# Call the Rooms API to look up a list of form IDs for the given forms library
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_libraries/$formsLibraryID/forms"

try {
    Write-Output "Response:"
    $response = Invoke-WebRequest -uri $uri -headers $headers -method GET
    # Retrieve the the first form ID provided
    $response.Content
    $obj = $response | ConvertFrom-Json
    $formID = $obj.forms[0].libraryFormId
}
catch {
    Write-Output "Unable to retrieve a form id"
    # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}

# Construct your request body
$body =
@"
 {"formId": "$formID" }
"@

# Call the Rooms API
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_groups/$formGroupID/assign_form"

try {
    $response = Invoke-WebRequest -uri $uri -headers $headers -method POST -Body $body
    Write-Output $response.Status
    Write-Output "Response: No JSON response body returned when setting the default office ID in a form group"
}
catch {
    Write-Output "Unable to assign the form to the form group"
    # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}
