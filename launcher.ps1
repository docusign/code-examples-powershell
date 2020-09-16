$ErrorActionPreference = "Stop" # force stop on failure

$configFile = ".\config\settings.txt"

if ((Test-Path $configFile) -eq $False) {
    Write-Output "`nError: "
    Write-Output "First copy the file '.\config\settings.example.txt' to '$configFile'."
    Write-Output "Next, fill in your API credentials, Signer name and email to continue.`n"
}

# If settings.txt file exist, we use all variables from this file
if (Test-Path $configFile) {
    Get-Content $configFile | Foreach-Object {
        $var = $_.Split('=')
        if ($var.Lengh -ne 2 -and $var[0].IsNullOrEmpty) {
            throw;
        }
        else {
            New-Variable -Name $var[0] -Value $var[1] -Force -Scope Global
        }
    }
}

function resetToken {
    Remove-Item -Path .\config\ds_access_token*
}

function login {
    do {
        Write-Output "Welcome to the DocuSign PowerShell Launcher"
        Write-Output "using Authorization Code grant or JWT grant authentication.`n"
        Write-Output "Choose an OAuth Strategy:`n"
        
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
                Invoke-Expression -Command .\OAuth\code_grant.ps1
                choices
            } '2' {
                Invoke-Expression -Command .\OAuth\jwt.ps1
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
            "Signing_Via_Email_With_Knoweldge_Based_Authentication"
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
            Write-Host "$($i+1)) $($list[$i])"
        }

        # Read method from console
        $CHOICE = Read-Host "Select the action"
        switch ($CHOICE) {
            '1' {
                Invoke-Expression .\examples\eg001EmbeddedSigning.ps1
                continu
            } '2' {
                # powershell.exe .\examples\eg002SigningViaEmail.ps1
                Write-Output "`nUnder construction...`n"
                continu 
            } '3' {
                Invoke-Expression .\examples\eg003ListEnvelopes.ps1
                continu
            } '4' {
                # powershell.exe .\examples\eg004EnvelopeInfo.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '5' {
                # powershell.exe .\examples\eg005EnvelopeRecipients.ps1
                Write-Output "`nUnder construction...`n"
                continu 
            } '6' {
                # powershell.exe .\examples\eg006EnvelopeDocs.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '7' {
                # powershell.exe .\examples\eg007EnvelopeGetDoc.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '8' {
                # powershell.exe .\examples\eg008CreateTemplate.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '9' {
                # powershell.exe .\examples\eg009UseTemplate.ps1
                Write-Output "`nUnder construction...`n"
                continu 
            } '10' {
                Invoke-Expression .\examples\eg010SendBinaryDocs.ps1
                continu
            } '11' {
                # powershell.exe .\examples\eg011EmbeddedSending.ps1
                Write-Output "`nUnder construction...`n"
                continu 
            } '12' {
                # powershell.exe .\examples\eg012EmbeddedConsole.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '13' {
                # powershell.exe .\examples\eg013AddDocToTemplate.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '14' {
                # powershell.exe .\examples\eg014CollectPayment.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '15' {
                # powershell.exe .\examples\eg015EnvelopeTabData.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '16' {
                # powershell.exe .\examples\eg016SetTabValues.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '17' {
                # powershell.exe .\examples\eg017SetTemplateTabValues.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '18' {
                # powershell.exe .\examples\eg018EnvelopeCustomFieldData.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '19' {
                # powershell.exe .\examples\eg019SigningViaEmailWithAccessCode.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '20' {
                # powershell.exe .\examples\eg020SigningViaEmailWithSmsAuthentication.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '21' {
                # powershell.exe .\examples\eg021SigningViaEmailWithPhoneAuthentication.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '22' {
                # powershell.exe .\examples\eg022SigningViaEmailWithKnoweldgeBasedAuthentication.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '23' {
                # powershell.exe .\examples\eg023SigningViaEmailWithIDVAuthentication.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '24' {
                # powershell.exe .\examples\eg024CreatingPermissionProfiles.ps1
                Write-Output "`nUnder construction...`n"
                continu 
            } '25' {
                # powershell.exe .\examples\eg025SettingPermissionProfiles.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '26' {
                # powershell.exe .\examples\eg026UpdatingIndividualPermission.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '27' {
                # powershell.exe .\examples\eg027DeletingPermissions.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '28' {
                # powershell.exe .\examples\eg028CreatingABrand.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '29' {
                # powershell.exe .\examples\eg029ApplyingBrandEnvelope.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '30' {
                # powershell.exe .\examples\eg030ApplyingBrandTemplate.ps1
                Write-Output "`nUnder construction...`n"
                continu
            } '31' {
                # powershell.exe .\examples\eg031BulkSending.ps1
                Write-Output "`nUnder construction...`n"
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
