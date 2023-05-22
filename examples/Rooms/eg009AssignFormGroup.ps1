# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
#ds-snippet-start:Rooms9Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Rooms9Step2

#ds-snippet-start:Rooms9Step3
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
} catch {
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
    Write-Output ""
    Write-Output "Response:"
    $response = Invoke-WebRequest -uri $uri -headers $headers -method GET
    $response.Content

    $formsObj = $($response.Content  | ConvertFrom-Json).forms

    Write-Output ""
    $menu = @{}
    for ($i=1;$i -le $formsObj.count; $i++) { 
        Write-Output "$i. $($formsObj[$i-1].name)"
        $menu.Add($i,($formsObj[$i-1].libraryFormId))
    }

    do {
        Write-Output ""
        [int]$selection = Read-Host 'Select a form by the form name: '
    } while ($selection -gt $formsObj.count -or $selection -lt 1);
    $formID = $menu.Item($selection)

    Write-Output ""
    Write-Output "Form Id: $formID"
} catch {
    Write-Output "Unable to retrieve a form id"
    # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}
#ds-snippet-end:Rooms9Step3

#ds-snippet-start:Rooms9Step4
$formGroupID = ""

# Call the Rooms API to look up a list of form group IDs
$uri = "${base_path}/restapi/v2/accounts/$APIAccountId/form_groups"
$result = Invoke-WebRequest -uri $uri -UseBasicParsing -headers $headers -method GET

Write-Output ""
Write-Output "Response:"
$result.Content

$formGroupObj = $($result.Content  | ConvertFrom-Json).formGroups
Write-Output ""

# Setup a temporary menu option to pick a form group
$menu = @{}
for ($i=1;$i -le $formGroupObj.count; $i++) { 
    Write-Output "$i. $($formGroupObj[$i-1].name)"
    $menu.Add($i,($formGroupObj[$i-1].formGroupId))
}

if ($formGroupObj.count -lt 1) {
   Write-Output "A form group ID is needed. Fix: execute code example 7 - Create a form group..."
   exit 1
}

do {
    Write-Output ""
    [int]$selection = Read-Host 'Select a form group: '
} while ($selection -gt $formGroupObj.count -or $selection -lt 1);
$formGroupID = $menu.Item($selection)

Write-Output ""
Write-Output "Form group Id: $formGroupID"
Write-Output ""
#ds-snippet-end:Rooms9Step4

#ds-snippet-start:Rooms9Step5
# Construct your request body
$body =
@"
 {"formId": "$formID" }
"@
#ds-snippet-end:Rooms9Step5

#ds-snippet-start:Rooms9Step6
# Call the Rooms API
$uri = "$base_path/restapi/v2/accounts/$APIAccountId/form_groups/$formGroupID/assign_form"

try {
    $response = Invoke-WebRequest -uri $uri -headers $headers -method POST -Body $body
    Write-Output $response.Status
    Write-Output "Response: No JSON response body returned when setting the default office ID in a form group"
} catch {
    Write-Output "Unable to assign the form to the form group"
    # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error

    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}
#ds-snippet-end:Rooms9Step6
