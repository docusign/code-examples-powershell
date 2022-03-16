# https://developers.docusign.com/docs/esign-rest-api/how-to/permission-profile-creating/

# Step 1: Obtain your OAuth token
# Note: Substitute these values with your own
$oAuthAccessToken = Get-Content .\config\ds_access_token.txt

#Set up variables for full code example
# Note: Substitute these values with your own
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

$PROFILE_NAME = Read-Host "Please enter a new permission profile name: "
$PROFILE_NAME > .\config\PROFILE_NAME

# Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $oAuthAccessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

# Construct the request body for your permission profile
$body = @"
{
    "permissionProfileName": "${PROFILE_NAME}",
    "settings" : {
        "useNewDocuSignExperienceInterface":0,
        "allowBulkSending":"true",
        "allowEnvelopeSending":"true",
        "allowSignerAttachments":"true",
        "allowTaggingInSendAndCorrect":"true",
        "allowWetSigningOverride":"true",
        "allowedAddressBookAccess":"personalAndShared",
        "allowedTemplateAccess":"share",
        "enableRecipientViewingNotifications":"true",
        "enableRecipientViewingNotifications":"true",
        "enableSequentialSigningInterface":"true",
        "receiveCompletedSelfSignedDocumentsAsEmailLinks":"false",
        "signingUiVersion":"v2",
        "useNewSendingInterface":"true",
        "allowApiAccess":"true",
        "allowApiAccessToAccount":"true",
        "allowApiSendingOnBehalfOfOthers":"true",
        "allowApiSequentialSigning":"true",
        "enableApiRequestLogging":"true",
        "allowDocuSignDesktopClient":"false",
        "allowSendersToSetRecipientEmailLanguage":"true",
        "allowVaulting":"false",
        "allowedToBeEnvelopeTransferRecipient":"true",
        "enableTransactionPointIntegration":"false",
        "powerFormRole":"admin",
        "vaultingMode":"none"
    }
}
"@

# a) Call the eSignature API
# b) Display the JSON response
$uri = "https://demo.docusign.net/restapi/v2.1/accounts/$APIAccountId/permission_profiles/"

try {
    Write-Output "Response:"
    $response = Invoke-WebRequest -uri $uri -headers $headers -body $body -method POST
    $($response.Content | ConvertFrom-Json).permissionProfileId > .\config\PROFILE_ID
    $response.Content
}
catch {
    Write-Output "Unable to create a new permissions profile."
    # On failure, display a notification, X-DocuSign-TraceToken, error message, and the command that triggered the error
    foreach ($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") { Write-Output "TraceToken : " $_.Exception.Response.Headers[$int] }
        $int++
    }
    Write-Output "Error : "$_.ErrorDetails.Message
    Write-Output "Command : "$_.InvocationInfo.Line
}