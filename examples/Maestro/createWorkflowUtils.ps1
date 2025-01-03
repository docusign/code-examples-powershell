. "utils/invokeScript.ps1"

# Check that we have a template id
if (-not (Test-Path .\config\TEMPLATE_ID)) {
    Write-Output "Creating template"
    Invoke-Script -Command "`".\examples\eSignature\eg008CreateTemplate.ps1`""
}

$templateId = Get-Content "config/TEMPLATE_ID"

Write-Host "Creating a new workflow"

$signerId = [guid]::NewGuid().ToString().ToLower()
$ccId = [guid]::NewGuid().ToString().ToLower()
$triggerId = "wfTrigger"

$accessToken = Get-Content "config/ds_access_token.txt"
$accountId = Get-Content "config/API_ACCOUNT_ID"

$base_path = "https://demo.services.docusign.net/aow-manage/v1.0"

$headers = @{
    'Authorization' = "Bearer $accessToken"
    'Accept'        = 'application/json'
    'Content-Type'  = 'application/json'
}

$body = @"
{
    "workflowDefinition": {
        "workflowName": "Example workflow - send invite to signer",
        "workflowDescription": "",
        "accountId": "$accountId",
        "documentVersion": "1.0.0",
        "schemaVersion": "1.0.0",
        "participants": {
            "$signerId": {
                "participantRole": "Signer"
            },
            "$ccId": {
                "participantRole": "CC"
            }
        },
        "trigger": {
            "name": "Get_URL",
            "type": "Http",
            "httpType": "Get",
            "id": "$triggerId",
            "input": {
                "metadata": {
                    "customAttributes": {}
                },
                "payload": {
                    "dacId_$triggerId": {
                        "source": "step",
                        "propertyName": "dacId",
                        "stepId": "$triggerId"
                    },
                    "id_$triggerId": {
                        "source": "step",
                        "propertyName": "id",
                        "stepId": "$triggerId"
                    },
                    "signerName_$triggerId": {
                        "source": "step",
                        "propertyName": "signerName",
                        "stepId": "$triggerId"
                    },
                    "signerEmail_$triggerId": {
                        "source": "step",
                        "propertyName": "signerEmail",
                        "stepId": "$triggerId"
                    },
                    "ccName_$triggerId": {
                        "source": "step",
                        "propertyName": "ccName",
                        "stepId": "$triggerId"
                    },
                    "ccEmail_$triggerId": {
                        "source": "step",
                        "propertyName": "ccEmail",
                        "stepId": "$triggerId"
                    }
                },
                "participants": {}
            },
            "output": {
                "dacId_$triggerId": {
                    "source": "step",
                    "propertyName": "dacId",
                    "stepId": "$triggerId"
                }
            }
        },
        "variables": {
            "dacId_$triggerId": {
                "source": "step",
                "propertyName": "dacId",
                "stepId": "$triggerId"
            },
            "id_$triggerId": {
                "source": "step",
                "propertyName": "id",
                "stepId": "$triggerId"
            },
            "signerName_$triggerId": {
                "source": "step",
                "propertyName": "signerName",
                "stepId": "$triggerId"
            },
            "signerEmail_$triggerId": {
                "source": "step",
                "propertyName": "signerEmail",
                "stepId": "$triggerId"
            },
            "ccName_$triggerId": {
                "source": "step",
                "propertyName": "ccName",
                "stepId": "$triggerId"
            },
            "ccEmail_$triggerId": {
                "source": "step",
                "propertyName": "ccEmail",
                "stepId": "$triggerId"
            },
            "envelopeId_step2": {
                "source": "step",
                "propertyName": "envelopeId",
                "stepId": "step2",
                "type": "String"
            },
            "combinedDocumentsBase64_step2": {
                "source": "step",
                "propertyName": "combinedDocumentsBase64",
                "stepId": "step2",
                "type": "File"
            },
            "fields.signer.text.value_step2": {
                "source": "step",
                "propertyName": "fields.signer.text.value",
                "stepId": "step2",
                "type": "String"
            }
        },
        "steps": [
            {
                "id": "step1",
                "name": "Set Up Invite",
                "moduleName": "Notification-SendEmail",
                "configurationProgress": "Completed",
                "type": "DS-EmailNotification",
                "config": {
                    "templateType": "WorkflowParticipantNotification",
                    "templateVersion": 1,
                    "language": "en",
                    "sender_name": "Docusign Orchestration",
                    "sender_alias": "Orchestration",
                    "participantId": "$signerId"
                },
                "input": {
                    "recipients": [
                        {
                            "name": {
                                "source": "step",
                                "propertyName": "signerName",
                                "stepId": "$triggerId"
                            },
                            "email": {
                                "source": "step",
                                "propertyName": "signerEmail",
                                "stepId": "$triggerId"
                            }
                        }
                    ],
                    "mergeValues": {
                        "CustomMessage": "Follow this link to access and complete the workflow.",
                        "ParticipantFullName": {
                            "source": "step",
                            "propertyName": "signerName",
                            "stepId": "$triggerId"
                        }
                    }
                },
                "output": {}
            },
            {
                "id": "step2",
                "name": "Get Signatures",
                "moduleName": "ESign",
                "configurationProgress": "Completed",
                "type": "DS-Sign",
                "config": {
                    "participantId": "$signerId"
                },
                "input": {
                    "isEmbeddedSign": true,
                    "documents": [
                        {
                            "type": "FromDSTemplate",
                            "eSignTemplateId": "$templateId"
                        }
                    ],
                    "emailSubject": "Please sign this document",
                    "emailBlurb": "",
                    "recipients": {
                        "signers": [
                            {
                                "defaultRecipient": "false",
                                "tabs": {
                                    "signHereTabs": [
                                        {
                                            "stampType": "signature",
                                            "name": "SignHere",
                                            "tabLabel": "Sign Here",
                                            "scaleValue": "1",
                                            "optional": "false",
                                            "documentId": "1",
                                            "recipientId": "1",
                                            "pageNumber": "1",
                                            "xPosition": "191",
                                            "yPosition": "148",
                                            "tabId": "1",
                                            "tabType": "signhere"
                                        }
                                    ],
                                    "textTabs": [
                                        {
                                            "requireAll": "false",
                                            "value": "",
                                            "required": "false",
                                            "locked": "false",
                                            "concealValueOnDocument": "false",
                                            "disableAutoSize": "false",
                                            "tabLabel": "text",
                                            "font": "helvetica",
                                            "fontSize": "size14",
                                            "localePolicy": {},
                                            "documentId": "1",
                                            "recipientId": "1",
                                            "pageNumber": "1",
                                            "xPosition": "153",
                                            "yPosition": "230",
                                            "width": "84",
                                            "height": "23",
                                            "tabId": "2",
                                            "tabType": "text"
                                        }
                                    ],
                                    "checkboxTabs": [
                                        {
                                            "name": "",
                                            "tabLabel": "ckAuthorization",
                                            "selected": "false",
                                            "selectedOriginal": "false",
                                            "requireInitialOnSharedChange": "false",
                                            "required": "true",
                                            "locked": "false",
                                            "documentId": "1",
                                            "recipientId": "1",
                                            "pageNumber": "1",
                                            "xPosition": "75",
                                            "yPosition": "417",
                                            "width": "0",
                                            "height": "0",
                                            "tabId": "3",
                                            "tabType": "checkbox"
                                        },
                                        {
                                            "name": "",
                                            "tabLabel": "ckAuthentication",
                                            "selected": "false",
                                            "selectedOriginal": "false",
                                            "requireInitialOnSharedChange": "false",
                                            "required": "true",
                                            "locked": "false",
                                            "documentId": "1",
                                            "recipientId": "1",
                                            "pageNumber": "1",
                                            "xPosition": "75",
                                            "yPosition": "447",
                                            "width": "0",
                                            "height": "0",
                                            "tabId": "4",
                                            "tabType": "checkbox"
                                        },
                                        {
                                            "name": "",
                                            "tabLabel": "ckAgreement",
                                            "selected": "false",
                                            "selectedOriginal": "false",
                                            "requireInitialOnSharedChange": "false",
                                            "required": "true",
                                            "locked": "false",
                                            "documentId": "1",
                                            "recipientId": "1",
                                            "pageNumber": "1",
                                            "xPosition": "75",
                                            "yPosition": "478",
                                            "width": "0",
                                            "height": "0",
                                            "tabId": "5",
                                            "tabType": "checkbox"
                                        },
                                        {
                                            "name": "",
                                            "tabLabel": "ckAcknowledgement",
                                            "selected": "false",
                                            "selectedOriginal": "false",
                                            "requireInitialOnSharedChange": "false",
                                            "required": "true",
                                            "locked": "false",
                                            "documentId": "1",
                                            "recipientId": "1",
                                            "pageNumber": "1",
                                            "xPosition": "75",
                                            "yPosition": "508",
                                            "width": "0",
                                            "height": "0",
                                            "tabId": "6",
                                            "tabType": "checkbox"
                                        }
                                    ],
                                    "radioGroupTabs": [
                                        {
                                            "documentId": "1",
                                            "recipientId": "1",
                                            "groupName": "radio1",
                                            "radios": [
                                                {
                                                    "pageNumber": "1",
                                                    "xPosition": "142",
                                                    "yPosition": "384",
                                                    "value": "white",
                                                    "selected": "false",
                                                    "tabId": "7",
                                                    "required": "false",
                                                    "locked": "false",
                                                    "bold": "false",
                                                    "italic": "false",
                                                    "underline": "false",
                                                    "fontColor": "black",
                                                    "fontSize": "size7"
                                                },
                                                {
                                                    "pageNumber": "1",
                                                    "xPosition": "74",
                                                    "yPosition": "384",
                                                    "value": "red",
                                                    "selected": "false",
                                                    "tabId": "8",
                                                    "required": "false",
                                                    "locked": "false",
                                                    "bold": "false",
                                                    "italic": "false",
                                                    "underline": "false",
                                                    "fontColor": "black",
                                                    "fontSize": "size7"
                                                },
                                                {
                                                    "pageNumber": "1",
                                                    "xPosition": "220",
                                                    "yPosition": "384",
                                                    "value": "blue",
                                                    "selected": "false",
                                                    "tabId": "9",
                                                    "required": "false",
                                                    "locked": "false",
                                                    "bold": "false",
                                                    "italic": "false",
                                                    "underline": "false",
                                                    "fontColor": "black",
                                                    "fontSize": "size7"
                                                }
                                            ],
                                            "shared": "false",
                                            "requireInitialOnSharedChange": "false",
                                            "requireAll": "false",
                                            "tabType": "radiogroup",
                                            "value": "",
                                            "originalValue": ""
                                        }
                                    ],
                                    "listTabs": [
                                        {
                                            "listItems": [
                                                {
                                                    "text": "Red",
                                                    "value": "red",
                                                    "selected": "false"
                                                },
                                                {
                                                    "text": "Orange",
                                                    "value": "orange",
                                                    "selected": "false"
                                                },
                                                {
                                                    "text": "Yellow",
                                                    "value": "yellow",
                                                    "selected": "false"
                                                },
                                                {
                                                    "text": "Green",
                                                    "value": "green",
                                                    "selected": "false"
                                                },
                                                {
                                                    "text": "Blue",
                                                    "value": "blue",
                                                    "selected": "false"
                                                },
                                                {
                                                    "text": "Indigo",
                                                    "value": "indigo",
                                                    "selected": "false"
                                                },
                                                {
                                                    "text": "Violet",
                                                    "value": "violet",
                                                    "selected": "false"
                                                }
                                            ],
                                            "value": "",
                                            "originalValue": "",
                                            "required": "false",
                                            "locked": "false",
                                            "requireAll": "false",
                                            "tabLabel": "list",
                                            "font": "helvetica",
                                            "fontSize": "size14",
                                            "localePolicy": {},
                                            "documentId": "1",
                                            "recipientId": "1",
                                            "pageNumber": "1",
                                            "xPosition": "142",
                                            "yPosition": "291",
                                            "width": "78",
                                            "height": "0",
                                            "tabId": "10",
                                            "tabType": "list"
                                        }
                                    ],
                                    "numericalTabs": [
                                        {
                                            "validationType": "currency",
                                            "value": "",
                                            "required": "false",
                                            "locked": "false",
                                            "concealValueOnDocument": "false",
                                            "disableAutoSize": "false",
                                            "tabLabel": "numericalCurrency",
                                            "font": "helvetica",
                                            "fontSize": "size14",
                                            "localePolicy": {
                                                "cultureName": "en-US",
                                                "currencyPositiveFormat": "csym_1_comma_234_comma_567_period_89",
                                                "currencyNegativeFormat": "opar_csym_1_comma_234_comma_567_period_89_cpar",
                                                "currencyCode": "usd"
                                            },
                                            "documentId": "1",
                                            "recipientId": "1",
                                            "pageNumber": "1",
                                            "xPosition": "163",
                                            "yPosition": "260",
                                            "width": "84",
                                            "height": "0",
                                            "tabId": "11",
                                            "tabType": "numerical"
                                        }
                                    ]
                                },
                                "signInEachLocation": "false",
                                "agentCanEditEmail": "false",
                                "agentCanEditName": "false",
                                "requireUploadSignature": "false",
                                "name": {
                                    "source": "step",
                                    "propertyName": "signerName",
                                    "stepId": "$triggerId"
                                },
                                "email": {
                                    "source": "step",
                                    "propertyName": "signerEmail",
                                    "stepId": "$triggerId"
                                },
                                "recipientId": "1",
                                "recipientIdGuid": "00000000-0000-0000-0000-000000000000",
                                "accessCode": "",
                                "requireIdLookup": "false",
                                "routingOrder": "1",
                                "note": "",
                                "roleName": "signer",
                                "completedCount": "0",
                                "deliveryMethod": "email",
                                "templateLocked": "false",
                                "templateRequired": "false",
                                "inheritEmailNotificationConfiguration": "false",
                                "recipientType": "signer"
                            }
                        ],
                        "carbonCopies": [
                            {
                                "agentCanEditEmail": "false",
                                "agentCanEditName": "false",
                                "name": {
                                    "source": "step",
                                    "propertyName": "ccName",
                                    "stepId": "$triggerId"
                                },
                                "email": {
                                    "source": "step",
                                    "propertyName": "ccEmail",
                                    "stepId": "$triggerId"
                                },
                                "recipientId": "2",
                                "recipientIdGuid": "00000000-0000-0000-0000-000000000000",
                                "accessCode": "",
                                "requireIdLookup": "false",
                                "routingOrder": "2",
                                "note": "",
                                "roleName": "cc",
                                "completedCount": "0",
                                "deliveryMethod": "email",
                                "templateLocked": "false",
                                "templateRequired": "false",
                                "inheritEmailNotificationConfiguration": "false",
                                "recipientType": "carboncopy"
                            }
                        ],
                        "certifiedDeliveries": []
                    }
                },
                "output": {
                    "envelopeId_step2": {
                        "source": "step",
                        "propertyName": "envelopeId",
                        "stepId": "step2",
                        "type": "String"
                    },
                    "combinedDocumentsBase64_step2": {
                        "source": "step",
                        "propertyName": "combinedDocumentsBase64",
                        "stepId": "step2",
                        "type": "File"
                    },
                    "fields.signer.text.value_step2": {
                        "source": "step",
                        "propertyName": "fields.signer.text.value",
                        "stepId": "step2",
                        "type": "String"
                    }
                }
            },
            {
                "id": "step3",
                "name": "Show a Confirmation Screen",
                "moduleName": "ShowConfirmationScreen",
                "configurationProgress": "Completed",
                "type": "DS-ShowScreenStep",
                "config": {
                    "participantId": "$signerId"
                },
                "input": {
                    "httpType": "Post",
                    "payload": {
                        "participantId": "$signerId",
                        "confirmationMessage": {
                            "title": "Tasks complete",
                            "description": "You have completed all your workflow tasks."
                        }
                    }
                },
                "output": {}
            }
        ]
    }
}
"@

# Create temporary file for response
$response = New-TemporaryFile

# Send request to create new workflow
try {
    $workflowDefinition = Invoke-RestMethod -Uri "$base_path/management/accounts/$accountId/workflowDefinitions" -Method POST -Headers $headers -body $body
    
    $workflow_id = $workflowDefinition.workflowDefinitionId
    Write-Host "Workflow ID: $workflow_id"
}
catch {
    Write-Host ""
    Write-Host "Unable to create a new workflow"
    Write-Host ""
    Get-Content $workflowDefinition.FullName
    Exit 0
}

# Define redirect_url
$redirect_url = "http://localhost:8080"

# Publish workflow
$published = $false
while (-not $published) {
    try {
        Invoke-RestMethod -Uri "$base_path/management/accounts/$accountId/workflowDefinitions/$workflow_id/publish?isPreRunCheck=true" -Method POST -Headers $Headers

        $published = $true
        $workflow_id | Out-File -FilePath "config/WORKFLOW_ID"
        Write-Host "Successfully created and published workflow $workflow_id, ID saved to config/WORKFLOW_ID"
    }
    catch {
        $message = $($_ | ConvertFrom-Json).message
        Write-Host $message
        if ($message -eq "Consent required") {
            $consentUrl = $($_ | ConvertFrom-Json).consentUrl
            Write-Host ""
            Write-Host "Please grant consent at the following URL to publish this workflow: $consentUrl&host=$redirect_url"
            
            # Wait for user to press Enter
            Read-Host "Press Enter to continue"
        } else {
            Write-Host $message
            Exit 0
        }
    }
}

# Remove the temporary files
Remove-Item $response
