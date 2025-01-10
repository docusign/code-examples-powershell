$apiUri = "https://demo.docusign.net/restapi"

# Step 1= Obtain your OAuth token
# Note= Substitute these values with your own
$accessToken = Get-Content .\config\ds_access_token.txt

# Set up variables for full code example
# Note= Substitute these values with your own
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json


# Create a template
#
#  The envelope has one document and one signer/recipient
#  The document must be a Word docx file
#  Adding five DocGen fields that will be dynamically set later

# temp files=
$requestData = New-TemporaryFile
$requestDataTemp = New-TemporaryFile
$doc1Base64 = New-TemporaryFile
$response = New-TemporaryFile


$templateName = "Example document generation template"

Write-Output "Sending the template create request to Docusign..."

# Fetch document and encode
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Resolve-Path ".\demo_documents\Offer_Letter_Dynamic_Table.docx"))) > $doc1Base64

# Concatenate the different parts of the request
#ds-snippet-start:eSign42Step2
@{
    description = "Example template created via the API";
    name = "${templateName}";
    shared = "false";
    documents = @(
        @{
            documentBase64 = "$(Get-Content $doc1Base64)";
            documentId = "1";
            fileExtension = "docx";
            order = "1";
            pages = "1";
            name = "Offer Letter Demo";
            isDocGenDocument = "true";

            };
        );
        emailSubject = "Please sign this document";
        recipients = @{
            signers = @(
                @{
                    recipientId = "1";
                    roleName = "signer";
                    routingOrder = "1";
                };
            );
        };
        status = "created";
    } | ConvertTo-Json -Depth 32 > $requestData

Write-Output "${apiUri}/v2.1/accounts/${accountId}/templates"

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/templates" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response

# pull out the template id
$templateId = $(Get-Content $response | ConvertFrom-Json).templateId
#ds-snippet-end:eSign42Step2
Write-Output "Template '${templateName}' was created! Template ID ${templateId}."

# Add a document with merge fields to your template
#ds-snippet-start:eSign42Step3
@{
  documents = @(
      @{
          documentBase64 = "$(Get-Content $doc1Base64)";
          documentId = "1";
          fileExtension = "docx";
          order = "1";
          pages = "1";
          name = "Offer Letter Demo";

      };
  );
} | ConvertTo-Json -Depth 32 > $requestData

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/templates/${templateId}/documents/1" `
    -Method 'PUT' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path  `
    -OutFile $response
#ds-snippet-end:eSign42Step3

# Add tabs to the template
#ds-snippet-start:eSign42Step4
@{
    signHereTabs   = @(
        @{
            anchorString = "Employee Signature";
            anchorUnits = "pixels";
            anchorXOffset = "5";
            anchorYOffset = "-22";
        };
    );
    dateSignedTabs   = @(
        @{
            anchorString = "Date Signed";
            anchorUnits = "pixels";
            anchorYOffset = "-22";
        };
    );
} | ConvertTo-Json -Depth 32 > $requestData


Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/templates/${templateId}/recipients/1/tabs" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path `
    -OutFile $response
#ds-snippet-end:eSign42Step4

# Create an envelope draft from a template
# Leave envelope in "draft"/"created" status, don't send it yet
#ds-snippet-start:eSign42Step5
@{
    templateId    = "${templateId}";
    templateRoles = @(
        @{
            email    = $variables.SIGNER_EMAIL;
            name     = $variables.SIGNER_NAME;
            roleName = "signer";
        };
    );
    status        = "created";
} | ConvertTo-Json -Depth 32 > $requestData

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes" `
    -Method 'POST' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path  `
    -OutFile $response

# pull out the envelope id
$envelopeId = $(Get-Content $response | ConvertFrom-Json).envelopeId
#ds-snippet-end:eSign42Step5

Write-Output "Envelope '${templateName}' draft was created! Envelope ID ${envelopeId}."

# Get DocGenFormFields
#ds-snippet-start:eSign42Step6
Invoke-RestMethod `
  -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/docGenFormFields" `
  -Method 'GET' `
  -Headers @{
  'Authorization' = "Bearer $accessToken";
  'Content-Type'  = "application/json";
} `
-OutFile $response

Write-Output "Response:"
Get-Content $response

# pull out the document id value
$documentId = $(Get-Content $response | ConvertFrom-Json).docGenFormFields[0].documentId
#ds-snippet-end:eSign42Step6

Write-Output "Document ID ${documentId}."

# Build the request to update the data fields in the envelope that we created from the template
# Collect user data to send to API/Document fields
$CandidateName  = Read-Host "Enter candidate name"
$ManagerName  = Read-Host "Enter manager name"
$StartDate  = Read-Host "Enter start date"
Write-Host "Enter salary: $" -NoNewLine
$Salary  = Read-Host
$Rsus  = Read-Host "Enter RSUs"
Write-Output "Choose job title"
Write-Output "1 - Software Engineer"
Write-Output "2 - Account Executive"
$JobTitle = "Software Engineer"
$JobNumber = Read-Host
if ($JobNumber -eq "2") {
    $JobTitle = "Account Executive"
}

#ds-snippet-start:eSign42Step7
@{
    docGenFormFields = @(
      @{
        documentId = "${documentId}";
        docGenFormFieldList = @(
          @{
            name = "Candidate_Name";
            value = "${CandidateName}";
          };
          @{
            name = "Job_Title";
            value = "${JobTitle}";
          };
          @{
            name = "Manager_Name";
            value = "${ManagerName}";
          };
          @{
            name = "Start_Date";
            value = "${StartDate}";
          };
          @{
            name = "Compensation_Package";
            type = "TableRow";
            rowValues = @(
              @{
                docGenFormFieldList = @(
                  @{
                    name = "Compensation_Component";
                    value = "Salary";
                  };
                  @{
                    name = "Details";
                    value = "$" + "${Salary}";
                  }
                )
              };
              @{
                docGenFormFieldList = @(
                  @{
                    name = "Compensation_Component";
                    value = "Bonus";
                  };
                  @{
                    name = "Details";
                    value = "20%";
                  }
                )
              };
              @{
                docGenFormFieldList = @(
                  @{
                    name = "Compensation_Component";
                    value = "RSUs";
                  };
                  @{
                    name = "Details";
                    value = $rsus;
                  }
                )
              }
            )
          }
        )
      }
    )
} | ConvertTo-Json -Depth 32 > $requestData

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/docgenformfields" `
    -Method 'PUT' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path  `
    -OutFile $response
#ds-snippet-end:eSign42Step7

# Send the envelope
#ds-snippet-start:eSign42Step8
@{
    status = "sent";
} | ConvertTo-Json -Depth 32 > $requestData

Invoke-RestMethod `
    -Uri "${apiUri}/v2.1/accounts/${accountId}/envelopes/${envelopeId}/" `
    -Method 'PUT' `
    -Headers @{
    'Authorization' = "Bearer $accessToken";
    'Content-Type'  = "application/json";
} `
    -InFile (Resolve-Path $requestData).Path  `
    -OutFile $response
#ds-snippet-end:eSign42Step8
Write-Output "Response:"
Get-Content $response


# cleanup
Remove-Item $requestData
Remove-Item $requestDataTemp
Remove-Item $response
Remove-Item $doc1Base64

Write-Output "Done."
