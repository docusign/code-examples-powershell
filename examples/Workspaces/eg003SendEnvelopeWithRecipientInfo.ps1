$apiUri = "https://api-d.docusign.com/v1"

# check that a workspace exists
$workspaceId = Get-Content .\config\WORKSPACE_ID
if ([string]::IsNullOrWhiteSpace($workspaceId)) {
    Write-Host "Please create a workspace before running this example"
    exit 0
}

# check that a document exists in the workspace
$documentId = Get-Content .\config\DOCUMENT_ID
if ([string]::IsNullOrWhiteSpace($documentId)) {
    Write-Host "Please create a document in the workspace before running this example"
    exit 0
}

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Obtain your OAuth token
# Note: Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note: Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

#ds-snippet-start:Workflows3Step2
$headers = @{
    'Authorization' = "Bearer $accessToken";
    'Accept'        = 'application/json';
    'Content-Type'  = "application/json";
}
#ds-snippet-end:Workflows3Step2

try {
    # Create the workspace envelope definition
    #apx-snippet-start:createWorkspaceEnvelope
    #ds-snippet-start:Workflows3Step3
    $body = @{
        "envelope_name" = "Example Workspace Envelope";
        "document_ids"  = @("${documentId}")
    } | ConvertTo-Json
    #ds-snippet-end:Workflows3Step3

    #ds-snippet-start:Workflows3Step4
    $response = $(Invoke-WebRequest `
        -Uri "${apiUri}/accounts/${accountId}/workspaces/${workspaceId}/envelopes" `
        -Method 'POST' `
        -headers $headers `
        -body $body)
    #ds-snippet-end:Workflows3Step4
    #apx-snippet-end:createWorkspaceEnvelope
} catch {
    Write-Output "Failed to send envelope."
    Write-Output $_
    exit 0
}

Write-Output "Response: $response"

# pull out the envelopeId
$envelopeId = $($response.Content | ConvertFrom-Json).envelope_id
Write-Output "Envelope created! ID: $envelopeId"

# Set the eSignature REST API base path
$apiUri = "https://demo.docusign.net/restapi"

#ds-snippet-start:Workflows3Step5
$body = @{
    emailSubject = "Please sign this document";
    recipients   = @{
        signers  = @(
            @{
                email        = $variables.SIGNER_EMAIL;
                name         = $variables.SIGNER_NAME;
                recipientId  = "1";
                routingOrder = "1";
                tabs         = @{
                    signHereTabs = @(
                        @{
                            anchorString  = "/sn1/";
                            anchorUnits   = "pixels";
                            anchorXOffset = "20";
                            anchorYOffset = "10";
                        };
                    );
                };
            };
        );
    };
    status = "sent";
} | ConvertTo-Json -Depth 32
#ds-snippet-end:Workflows3Step5

try {
    #ds-snippet-start:Workflows3Step6
    $response = $(Invoke-WebRequest `
        -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}" `
        -Method 'PUT' `
        -headers $headers `
        -body $body)
    #ds-snippet-end:Workflows3Step6
} catch {
    Write-Output "Failed to send envelope."
    Write-Output $_
    exit 0
}

Write-Output "Response: $response"
Write-Output "Envelope Sent!"
Write-Output "Done."
