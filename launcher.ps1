$ErrorActionPreference = "Stop" # force stop on failure

$configFile = ".\config\settings.json"

if ((Test-Path $configFile) -eq $False) {
    Write-Output "Error: "
    Write-Output "First copy the file '.\config\settings.example.json' to '$configFile'."
    Write-Output "Next, fill in your API credentials, Signer name and email to continue."
}

# Get required environment variables from .\config\settings.json file
$config = Get-Content $configFile -Raw | ConvertFrom-Json

function login {
    do {
        Write-Output "Welcome to the DocuSign PowerShell Launcher"
        Write-Output "using Authorization Code grant or JWT grant authentication."
        Write-Output "Choose an OAuth Strategy:"

        # Create a List with Login methods
        $list = @(
            "Use_Authorization_Code_Grant",
            "Use_JSON_Web_Token",
            "Exit"
        )

        # Create a blank array to hold menu
        $formattedList = @()
        # Even Odd Columns
        for ($i = 0; $i -lt $list.Count; $i += 1) {
            if ($null -ne $list[$i + 1]) {
                $formattedList += [PSCustomObject]@{
                    Odd = "$($i+1)) $($list[$i])";
                }
            }
            else {
                $formattedList += [PSCustomObject]@{
                    Odd  = "$($i+1)) $($list[$i])";
                    Even = ""
                }
            }
        }
        # Output menu
        $formattedList | Format-Table -HideTableHeaders

        # Read method from console
        $METHOD = Read-Host "Select an OAuth method to Authenticate with your DocuSign account"
        switch ($METHOD) {
            '1' {
                . .\OAuth\code_grant.ps1 -clientId $($config.INTEGRATION_KEY_AUTH_CODE) -clientSecret $($config.SECRET_KEY)
                choices
            } '2' {
                powershell.exe -Command .\OAuth\jwt.ps1
                choices
            } '3' {
                exit 0
            }
        }
        pause
    } until ($METHOD -eq '3')

    # Set Environment Variable
    $env:API_ACCOUNT_ID = $API_ACCOUNT_ID
    # Get Token
    $token_file_name = ".\ds_access_token.txt"
    # Set Environment Variable
    $env:ACCESS_TOKEN_VALUE = $(Get-Content $token_file_name)
}

function choices {
    do {
        # Create List with the code-examples
        $list = @(
            "Embedded_Signing"
            "Signing_Via_Email"
            "List_Envelopes"
            "Envelope_Info"
            "Envelope_Recipients"
            "Envelope_Docs"
            "Envelope_Get_Doc"
            "Create_Template"
            "Use_Template"
            "Send_Binary_Docs"
            "Embedded_Sending"
            "Embedded_Console"
            "Add_Doc_To_Template"
            "Collect_Payment"
            "Envelope_Tab_Data"
            "Set_Tab_Values"
            "Set_Template_Tab_Values"
            "Envelope_Custom_Field_Data"
            "Signing_Via_Email_With_Access_Code"
            "Signing_Via_Email_With_Sms_Authentication"
            "Signing_Via_Email_With_Phone_Authentication"
            "Signing_Via_Email_With_Knowledge_Based_Authentication"
            "Signing_Via_Email_With_IDV_Authentication"
            "Creating_Permission_Profiles"
            "Setting_Permission_Profiles"
            "Updating_Individual_Permission"
            "Deleting_Permissions"
            "Creating_A_Brand"
            "Applying_Brand_Envelope"
            "Applying_Brand_Template"
            "Bulk_Sending"
            "Home"
        )

        # Show Columns
        for ($i = 0; $i -lt $list.Count; $i++) {
            Write-Output "$($i+1)) $($list[$i])"
        }

        # Read method from console
        $CHOICE = Read-Host "Select the action"
        switch ($CHOICE) {
            '1' {
                powershell.exe -Command .\eg001EmbeddedSigning.ps1
                continu
            } '2' {
                powershell.exe -Command .\examples\eSignature\eg002SigningViaEmail.ps1
                continu
            } '3' {
                powershell.exe -Command .\examples\eSignature\eg003ListEnvelopes.ps1
                continu
            } '4' {
                powershell.exe -Command .\examples\eSignature\eg004EnvelopeInfo.ps1
                continu
            } '5' {
                powershell.exe .\examples\eSignature\eg005EnvelopeRecipients.ps1
                continu
            } '6' {
                powershell.exe .\examples\eSignature\eg006EnvelopeDocs.ps1
                continu
            } '7' {
                powershell.exe .\examples\eSignature\eg007EnvelopeGetDoc.ps1
                continu
            } '8' {
                powershell.exe .\examples\eSignature\eg008CreateTemplate.ps1
                continu
            } '9' {
                powershell.exe .\examples\eSignature\eg009UseTemplate.ps1
                continu
            } '10' {
                powershell.exe .\examples\eSignature\eg010SendBinaryDocs.ps1
                continu
            } '11' {
                powershell.exe .\examples\eSignature\eg011EmbeddedSending.ps1
                continu
            } '12' {
                powershell.exe .\examples\eSignature\eg012EmbeddedConsole.ps1
                continu
            } '13' {
                powershell.exe .\examples\eSignature\eg013AddDocToTemplate.ps1
                continu
            } '14' {
                powershell.exe .\examples\eSignature\eg014CollectPayment.ps1
                continu
            } '15' {
                powershell.exe .\examples\eSignature\eg015EnvelopeTabData.ps1
                continu
            } '16' {
                powershell.exe .\examples\eSignature\eg016SetTabValues.ps1
                continu
            } '17' {
                powershell.exe .\examples\eSignature\eg017SetTemplateTabValues.ps1
                continu
            } '18' {
                powershell.exe .\examples\eSignature\eg018EnvelopeCustomFieldData.ps1
                continu
            } '19' {
                # powershell.exe .\examples\eSignature\eg019SigningViaEmailWithAccessCode.ps1
                Write-Output "Under construction..."
                continu
            } '20' {
                # powershell.exe .\examples\eSignature\eg020SigningViaEmailWithSmsAuthentication.ps1
                Write-Output "Under construction..."
                continu
            } '21' {
                # powershell.exe .\examples\eSignature\eg021SigningViaEmailWithPhoneAuthentication.ps1
                Write-Output "Under construction..."
                continu
            } '22' {
                # powershell.exe .\examples\eSignature\eg022SigningViaEmailWithKnoweldgeBasedAuthentication.ps1
                Write-Output "Under construction..."
                continu
            } '23' {
                # powershell.exe .\examples\eSignature\eg023SigningViaEmailWithIDVAuthentication.ps1
                Write-Output "Under construction..."
                continu
            } '24' {
                # powershell.exe .\examples\eSignature\eg024CreatingPermissionProfiles.ps1
                Write-Output "Under construction..."
                continu
            } '25' {
                # powershell.exe .\examples\eSignature\eg025SettingPermissionProfiles.ps1
                Write-Output "Under construction..."
                continu
            } '26' {
                # powershell.exe .\examples\eSignature\eg026UpdatingIndividualPermission.ps1
                Write-Output "Under construction..."
                continu
            } '27' {
                # powershell.exe .\examples\eSignature\eg027DeletingPermissions.ps1
                Write-Output "Under construction..."
                continu
            } '28' {
                # powershell.exe .\examples\eSignature\eg028CreatingABrand.ps1
                Write-Output "Under construction..."
                continu
            } '29' {
                # powershell.exe .\examples\eSignature\eg029ApplyingBrandEnvelope.ps1
                Write-Output "Under construction..."
                continu
            } '30' {
                # powershell.exe .\examples\eSignature\eg030ApplyingBrandTemplate.ps1
                Write-Output "Under construction..."
                continu
            } '31' {
                # powershell.exe .\examples\eSignature\eg031BulkSending.ps1
                Write-Output "Under construction..."
                continu
            } '32' {
                login
            }
        }
        pause
    }
    until ($CHOICE -eq '32')
}

function continu {
    Read-Host "press the 'any' key to continue"
    choices
}

login
