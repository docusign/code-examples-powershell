$ErrorActionPreference = "Stop" # force stop on failure

$configFile = ".\config\settings.json"

if ((Test-Path $configFile) -eq $False) {
    Write-Output "Error: "
    Write-Output "First copy the file '.\config\settings.example.json' to '$configFile'."
    Write-Output "Next, fill in your API credentials, Signer name and email to continue."
}

# Get required environment variables from .\config\settings.json file
$config = Get-Content $configFile -Raw | ConvertFrom-Json

function startLauncher {
    do {
        # Preparing list of Api
        Enum listApi {
            eSignature = 1;
            Rooms = 2;
            Click = 3;
            Exit = 4;
        }

        $listApiView = $null;
        do {
            Write-Output 'Choose API: '
            Write-Output "$([int][listApi]::eSignature)) eSignature"
            Write-Output "$([int][listApi]::Rooms)) Rooms"
            Write-Output "$([int][listApi]::Click)) Click"
            Write-Output "$([int][listApi]::Exit)) Exit"
            [int]$listApiView = Read-Host "Please make a selection"
        } while (-not [listApi]::IsDefined([listApi], $listApiView));

        if ($listApiView -eq [listApi]::eSignature) {
            startAuth "eSignature"
        }
        elseif ($listApiView -eq [listApi]::Rooms) {
            startAuth "rooms"
        }
        elseif ($listApiView -eq [listApi]::Click) {
            startAuth "click"
        }
        elseif ($listApiView -eq [listApi]::Exit) {
            exit 1
        }
    } until ($listApiView -eq [listApi]::Exit)
}

function startAuth ($apiVersion) {
    # Preparing a list of Authorization methods
    Enum AuthType {
        CodeGrant = 1;
        JWT = 2;
        Exit = 3;
    }

    $AuthTypeView = $null;
    do {
        Write-Output ""
        Write-Output 'Choose an OAuth Strategy: '
        Write-Output "$([int][AuthType]::CodeGrant)) Authorization Code Grant"
        Write-Output "$([int][AuthType]::JWT)) Json Web Token"
        Write-Output "$([int][AuthType]::Exit)) Exit"
        [int]$AuthTypeView = Read-Host "Select an OAuth method to Authenticate with your DocuSign account"
    } while (-not [AuthType]::IsDefined([AuthType], $AuthTypeView));

    if ($AuthTypeView -eq [AuthType]::Exit) {
        startLauncher
    }
    elseif ($AuthTypeView -eq [AuthType]::CodeGrant) {
        . .\OAuth\code_grant.ps1 -clientId $($config.INTEGRATION_KEY_AUTH_CODE) -clientSecret $($config.SECRET_KEY) -apiVersion $($apiVersion)
    }
    elseif ($AuthTypeView -eq [AuthType]::JWT) {
        powershell.exe -Command .\OAuth\jwt.ps1 -clientId $($config.INTEGRATION_KEY_AUTH_CODE) -apiVersion $($apiVersion)
    }

    if ($listApiView -eq [listApi]::eSignature) {
        startSignature
    }
    elseif ($listApiView -eq [listApi]::Rooms) {
        startRooms
    }
    elseif ($listApiView -eq [listApi]::Click) {
        startClick
    }
}

function startSignature {
    do {
        # Preparing a list of eSignature examples
        Enum ApiExamples {
            Embedded_Signing = 1;
            Signing_Via_Email = 2;
            List_Envelopes = 3;
            Envelope_Info = 4;
            Envelope_Recipients = 5;
            Envelope_Docs = 6;
            Envelope_Get_Doc = 7;
            Create_Template = 8;
            Use_Template = 9;
            Send_Binary_Docs = 10;
            Embedded_Sending = 11;
            Embedded_Console = 12;
            Add_Doc_To_Template = 13;
            Collect_Payment = 14;
            Envelope_Tab_Data = 15;
            Set_Tab_Values = 16;
            Set_Template_Tab_Values = 17;
            Envelope_Custom_Field_Data = 18;
            Signing_Via_Email_With_Access_Code = 19;
            Signing_Via_Email_With_Sms_Authentication = 20;
            Signing_Via_Email_With_Phone_Authentication = 21;
            Signing_Via_Email_With_Knowledge_Based_Authentication = 22;
            Signing_Via_Email_With_IDV_Authentication = 23;
            Creating_Permission_Profiles = 24;
            Setting_Permission_Profiles = 25;
            Updating_Individual_Permission = 26;
            Deleting_Permissions = 27;
            Creating_A_Brand = 28;
            Applying_Brand_Envelope = 29;
            Applying_Brand_Template = 30;
            Bulk_Sending = 31;
            Pause_Signature_Workflow = 32;
            Unpause_Signature_Workflow = 33;
            Use_Conditional_Recipients = 34;
            Home = 35;
        }

        $ApiExamplesView = $null;
        do {
            Write-Output ""
            Write-Output 'Select the action: '
            Write-Output "$([int][ApiExamples]::Embedded_Signing)) Embedded_Signing"
            Write-Output "$([int][ApiExamples]::Signing_Via_Email)) Signing_Via_Email"
            Write-Output "$([int][ApiExamples]::List_Envelopes)) List_Envelopes"
            Write-Output "$([int][ApiExamples]::Envelope_Info)) Envelope_Info"
            Write-Output "$([int][ApiExamples]::Envelope_Recipients)) Envelope_Recipients"
            Write-Output "$([int][ApiExamples]::Envelope_Docs)) Envelope_Docs"
            Write-Output "$([int][ApiExamples]::Envelope_Get_Doc)) Envelope_Get_Doc"
            Write-Output "$([int][ApiExamples]::Create_Template)) Create_Template"
            Write-Output "$([int][ApiExamples]::Use_Template)) Use_Template"
            Write-Output "$([int][ApiExamples]::Send_Binary_Docs)) Send_Binary_Docs"
            Write-Output "$([int][ApiExamples]::Embedded_Sending)) Embedded_Sending"
            Write-Output "$([int][ApiExamples]::Embedded_Console)) Embedded_Console"
            Write-Output "$([int][ApiExamples]::Add_Doc_To_Template)) Add_Doc_To_Template"
            Write-Output "$([int][ApiExamples]::Collect_Payment)) Collect_Payment"
            Write-Output "$([int][ApiExamples]::Envelope_Tab_Data)) Envelope_Tab_Data"
            Write-Output "$([int][ApiExamples]::Set_Tab_Values)) Set_Tab_Values"
            Write-Output "$([int][ApiExamples]::Set_Template_Tab_Values)) Set_Template_Tab_Values"
            Write-Output "$([int][ApiExamples]::Envelope_Custom_Field_Data)) Envelope_Custom_Field_Data"
            Write-Output "$([int][ApiExamples]::Signing_Via_Email_With_Access_Code)) Signing_Via_Email_With_Access_Code"
            Write-Output "$([int][ApiExamples]::Signing_Via_Email_With_Sms_Authentication)) Signing_Via_Email_With_Sms_Authentication"
            Write-Output "$([int][ApiExamples]::Signing_Via_Email_With_Phone_Authentication)) Signing_Via_Email_With_Phone_Authentication"
            Write-Output "$([int][ApiExamples]::Signing_Via_Email_With_Knowledge_Based_Authentication)) Signing_Via_Email_With_Knowledge_Based_Authentication"
            Write-Output "$([int][ApiExamples]::Signing_Via_Email_With_IDV_Authentication)) Signing_Via_Email_With_IDV_Authentication"
            Write-Output "$([int][ApiExamples]::Creating_Permission_Profiles)) Creating_Permission_Profiles"
            Write-Output "$([int][ApiExamples]::Setting_Permission_Profiles)) Setting_Permission_Profiles"
            Write-Output "$([int][ApiExamples]::Updating_Individual_Permission)) Updating_Individual_Permission"
            Write-Output "$([int][ApiExamples]::Deleting_Permissions)) Deleting_Permissions"
            Write-Output "$([int][ApiExamples]::Creating_A_Brand)) Creating_A_Brand"
            Write-Output "$([int][ApiExamples]::Applying_Brand_Envelope)) Applying_Brand_Envelope"
            Write-Output "$([int][ApiExamples]::Applying_Brand_Template)) Applying_Brand_Template"
            Write-Output "$([int][ApiExamples]::Bulk_Sending)) Bulk_Sending"
            Write-Output "$([int][ApiExamples]::Pause_Signature_Workflow)) Pause_Signature_Workflow"
            Write-Output "$([int][ApiExamples]::Unpause_Signature_Workflow)) Unpause_Signature_Workflow"
            Write-Output "$([int][ApiExamples]::Use_Conditional_Recipients)) Use_Conditional_Recipients"
            Write-Output "$([int][ApiExamples]::Home)) Home"
            [int]$ApiExamplesView = Read-Host "Select the action"
        } while (-not [ApiExamples]::IsDefined([ApiExamples], $ApiExamplesView));

        if ($ApiExamplesView -eq [ApiExamples]::Embedded_Signing) {
            powershell.exe -Command .\eg001EmbeddedSigning.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Signing_Via_Email) {
            powershell.exe -Command .\examples\eSignature\eg002SigningViaEmail.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::List_Envelopes) {
            powershell.exe -Command .\examples\eSignature\eg003ListEnvelopes.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Envelope_Info) {
            powershell.exe -Command .\examples\eSignature\eg004EnvelopeInfo.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Envelope_Recipients) {
            powershell.exe .\examples\eSignature\eg005EnvelopeRecipients.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Envelope_Docs) {
            powershell.exe .\examples\eSignature\eg006EnvelopeDocs.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Envelope_Get_Doc) {
            powershell.exe .\examples\eSignature\eg007EnvelopeGetDoc.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Create_Template) {
            powershell.exe .\examples\eSignature\eg008CreateTemplate.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Use_Template) {
            powershell.exe .\examples\eSignature\eg009UseTemplate.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Send_Binary_Docs) {
            powershell.exe .\examples\eSignature\eg010SendBinaryDocs.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Embedded_Sending) {
            powershell.exe .\examples\eSignature\eg011EmbeddedSending.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Embedded_Console) {
            powershell.exe .\examples\eSignature\eg012EmbeddedConsole.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Add_Doc_To_Template) {
            powershell.exe .\examples\eSignature\eg013AddDocToTemplate.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Collect_Payment) {
            powershell.exe .\examples\eSignature\eg014CollectPayment.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Envelope_Tab_Data) {
            powershell.exe .\examples\eSignature\eg015EnvelopeTabData.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Set_Tab_Values) {
            powershell.exe .\examples\eSignature\eg016SetTabValues.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Set_Template_Tab_Values) {
            powershell.exe .\examples\eSignature\eg017SetTemplateTabValues.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Envelope_Custom_Field_Data) {
            powershell.exe .\examples\eSignature\eg018EnvelopeCustomFieldData.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Signing_Via_Email_With_Access_Code) {
            powershell.exe .\examples\eSignature\eg019SigningViaEmailWithAccessCode.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Signing_Via_Email_With_Sms_Authentication) {
            powershell.exe .\examples\eSignature\eg020SigningViaEmailWithSmsAuthentication.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Signing_Via_Email_With_Phone_Authentication) {
            powershell.exe .\examples\eSignature\eg021SigningViaEmailWithPhoneAuthentication.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Signing_Via_Email_With_Knowledge_Based_Authentication) {
            powershell.exe .\examples\eSignature\eg022SigningViaEmailWithKnoweldgeBasedAuthentication.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Signing_Via_Email_With_IDV_Authentication) {
            powershell.exe .\examples\eSignature\eg023SigningViaEmailWithIDVAuthentication.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Creating_Permission_Profiles) {
            powershell.exe .\examples\eSignature\eg024CreatingPermissionProfiles.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Setting_Permission_Profiles) {
            powershell.exe .\examples\eSignature\eg025SettingPermissionProfiles.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Updating_Individual_Permission) {
            powershell.exe .\examples\eSignature\eg026UpdatingIndividualPermission.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Deleting_Permissions) {
            powershell.exe .\examples\eSignature\eg027DeletingPermissions.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Creating_A_Brand) {
            powershell.exe .\examples\eSignature\eg028CreatingABrand.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Applying_Brand_Envelope) {
            powershell.exe .\examples\eSignature\eg029ApplyingBrandEnvelope.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Applying_Brand_Template) {
            powershell.exe .\examples\eSignature\eg030ApplyingBrandTemplate.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Bulk_Sending) {
            powershell.exe .\examples\eSignature\eg031BulkSending.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Pause_Signature_Workflow) {
            powershell.exe .\examples\eSignature\eg032PauseSignatureWorkflow.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Unpause_Signature_Workflow) {
            powershell.exe .\examples\eSignature\eg033UnpauseSignatureWorkflow.ps1
        }
        elseif ($ApiExamplesView -eq [ApiExamples]::Use_Conditional_Recipients) {
            powershell.exe .\examples\eSignature\eg034UseConditionalRecipients.ps1
        }
    } until ($ApiExamplesView -eq [ApiExamples]::Home)
    startLauncher
}

function startRooms {
    do {
        Enum listRoomExamples {
            CreateRoomWithDataController = 1;
            CreateRoomWithTemplateController = 2;
            ExportDataFromRoomController = 3;
            AddFormsToRoomController = 4;
            GetRoomsWithFiltersController = 5;
            CreateAnExternalFormFillSessionController = 6;
            Home = 7;
        }
        $listRoomExamplesView = $null;
        do {
            Write-Output ""
            Write-Output 'Select the action: '
            Write-Output "$([int][listRoomExamples]::CreateRoomWithDataController)) Create room with data controller"
            Write-Output "$([int][listRoomExamples]::CreateRoomWithTemplateController)) Create room with template controller"
            Write-Output "$([int][listRoomExamples]::ExportDataFromRoomController)) Export data from room controller"
            Write-Output "$([int][listRoomExamples]::AddFormsToRoomController)) Add forms to room controller"
            Write-Output "$([int][listRoomExamples]::GetRoomsWithFiltersController)) Get rooms with filters controller"
            Write-Output "$([int][listRoomExamples]::CreateAnExternalFormFillSessionController)) Create an external form fill session controller"
            Write-Output "$([int][listRoomExamples]::Home)) Home"
            [int]$listRoomExamplesView = Read-Host "Select the action"
        } while (-not [listRoomExamples]::IsDefined([listRoomExamples], $listRoomExamplesView));

        if ($listRoomExamplesView -eq [listRoomExamples]::CreateRoomWithDataController) {
            powershell.exe -Command .\examples\Rooms\eg001CreateRoomWithDataController.ps1
        }
        elseif ($listRoomExamplesView -eq [listRoomExamples]::CreateRoomWithTemplateController) {
            powershell.exe -Command .\examples\Rooms\eg002CreateRoomWithTemplateController.ps1
        }
        elseif ($listRoomExamplesView -eq [listRoomExamples]::ExportDataFromRoomController) {
            powershell.exe -Command .\examples\Rooms\eg003ExportDataFromRoomController.ps1
        }
        elseif ($listRoomExamplesView -eq [listRoomExamples]::AddFormsToRoomController) {
            powershell.exe -Command .\examples\Rooms\eg004AddFormsToRoomController.ps1
        }
        elseif ($listRoomExamplesView -eq [listRoomExamples]::GetRoomsWithFiltersController) {
            powershell.exe -Command .\examples\Rooms\eg005GetRoomsWithFiltersController.ps1
        }
        elseif ($listRoomExamplesView -eq [listRoomExamples]::CreateAnExternalFormFillSessionController) {
            powershell.exe -Command .\examples\Rooms\eg006CreateAnExternalFormFillSessionController.ps1
        }
    } until ($listRoomExamplesView -eq [listRoomExamples]::Home)
    startLauncher
}

function startClick {
    do {
        Enum listClickExamples {
            createClickwrap = 1;
            activateClickwrap = 2;
            testClickwrap = 3;
            embedClickwraps = 4;
            clickwrapVersioning = 5;
            retrieveClickwraps = 6;
            getClickwrapResponses = 7;
            Home = 8;
        }
        $listClickExamplesView = $null;
        do {
            Write-Output ""
            Write-Output 'Select the action: '
            Write-Output "$([int][listClickExamples]::createClickwrap)) Create Clickwrap"
            Write-Output "$([int][listClickExamples]::activateClickwrap)) Activate Clickwrap"
            Write-Output "$([int][listClickExamples]::testClickwrap)) Test Clickwrap"
            Write-Output "$([int][listClickExamples]::embedClickwraps)) Embed Clickwraps"
            Write-Output "$([int][listClickExamples]::clickwrapVersioning)) Clickwrap Versioning"
            Write-Output "$([int][listClickExamples]::retrieveClickwraps)) Retrieve Clickwraps"
            Write-Output "$([int][listClickExamples]::getClickwrapResponses)) Get Clickwrap Responses"
            Write-Output "$([int][listClickExamples]::Home)) Home"
            [int]$listClickExamplesView = Read-Host "Select the action"
        } while (-not [listClickExamples]::IsDefined([listClickExamples], $listClickExamplesView));

        if ($listClickExamplesView -eq [listClickExamples]::createClickwrap) {
            powershell.exe -Command .\examples\Click\eg001CreateClickwrap.ps1
        }
        elseif ($listClickExamplesView -eq [listClickExamples]::activateClickwrap) {
            powershell.exe -Command .\examples\Click\eg002ActivateClickwrap.ps1
        }
        elseif ($listClickExamplesView -eq [listClickExamples]::testClickwrap) {
            powershell.exe -Command .\examples\Click\eg003TestClickwrap.ps1
        }
        elseif ($listClickExamplesView -eq [listClickExamples]::embedClickwraps) {
            powershell.exe -Command .\examples\Click\eg004EmbedClickwrap.ps1
        }
        elseif ($listClickExamplesView -eq [listClickExamples]::clickwrapVersioning) {
            powershell.exe -Command .\examples\Click\eg005CreateNewClickwrapVersion.ps1
        }
        elseif ($listClickExamplesView -eq [listClickExamples]::retrieveClickwraps) {
            powershell.exe -Command .\examples\Click\eg006GetListOfClickwraps.ps1
        }
        elseif ($listClickExamplesView -eq [listClickExamples]::getClickwrapResponses) {
            powershell.exe -Command .\examples\Click\eg007GetClickwrapResponses.ps1
        }
    } until ($listClickExamplesView -eq [listClickExamples]::Home)
    startLauncher
}

Write-Output "Welcome to the DocuSign PowerShell Launcher"
startLauncher
