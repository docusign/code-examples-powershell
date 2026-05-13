# Ensure the config directory exists
if (-not (Test-Path "config")) {
    New-Item -ItemType Directory -Path "config" | Out-Null
}

# Load credentials from files
$access_token = Get-Content "../../config/ds_access_token.txt" -Raw | ForEach-Object { $_.Trim() }
$account_id = Get-Content "../../config/API_ACCOUNT_ID" -Raw | ForEach-Object { $_.Trim() }

# --- ID Input Selection ---
Write-Host "Have you already completed one of the following: IDNow for GwG, Identity Verification, or a Maestro 'Verify Identity' step?" -ForegroundColor Cyan
$has_completed = Read-Host "(y/n)"

if ($has_completed -match "^[Yy]$") {
    Write-Host "-------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "NOTE: In the case of eSignature, the Recipient ID and the Record ID are the same." -ForegroundColor Yellow
    Write-Host "-------------------------------------------------------" -ForegroundColor Yellow
    
    Write-Host "Do you have an (1) Envelope ID or a (2) Record ID?"
    $id_type = Read-Host "Enter 1 or 2"

    if ($id_type -eq "1") {
        $idv_envelope_id = Read-Host "Please enter the Envelope ID"
        
        if ([string]::IsNullOrWhiteSpace($idv_envelope_id)) {
            Write-Host "Error: To retrieve the data, either an Envelope ID or Record ID is required. Please try again." -ForegroundColor Red
            exit
        }

        Write-Host "Retrieving Record ID from envelope recipients..."
        #ds-snippet-start:TrustRecords1Step2
        $uri = "https://demo.docusign.net/restapi/v2.1/accounts/$account_id/envelopes/$idv_envelope_id/recipients"
        
        try {
            $headers = @{
                "Authorization" = "Bearer $access_token"
                "Accept"        = "application/json"
            }
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            
            # Extract the first recipientIdGuid to use as record_id
            $record_id = $response.signers[0].recipientIdGuid
            Write-Host "Found Record ID: $record_id"
        }
        catch {
            Write-Host "Failed to retrieve recipients. Error: $_" -ForegroundColor Red
            exit
        }
        #ds-snippet-end:TrustRecords1Step2
    }
    elseif ($id_type -eq "2") {
        $record_id = Read-Host "Please enter the Record ID"
    }
    else {
        Write-Host "Invalid selection. To retrieve the data, either an Envelope ID or Record ID is required. Please try again." -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "To retrieve the data, either an Envelope ID or Record ID is required. Please try again." -ForegroundColor Red
    exit
}

# Final check for Record ID
if ([string]::IsNullOrWhiteSpace($record_id)) {
    Write-Host "Error: Record ID is missing. To retrieve the data, either an Envelope ID or Record ID is required. Please try again." -ForegroundColor Red
    exit
}

# Save Record ID internally
$record_id | Out-File "../../config/RECIPIENT_ID_GUID" -NoNewline

# --- Step 4: Call Trust Records Endpoint ---
#ds-snippet-start:TrustRecords1Step4
$uri = "https://api-d.docusign.com/v1/accounts/$account_id/trust-records/$record_id"
#ds-snippet-end:TrustRecords1Step4

Write-Host "`n-------------------------------------------------------"
Write-Host "Fetching Trust Records for Record ID: $record_id"
Write-Host "-------------------------------------------------------"
#ds-snippet-start:TrustRecords1Step3
try {
    $headers = @{
        "Authorization" = "Bearer $access_token"
        "Accept"        = "application/json"
    }
    
    $apiResponse = Invoke-WebRequest -Uri $uri -Headers $headers -Method Get
  #ds-snippet-end:TrustRecords1Step3  
    Write-Host "API Response Content:"
    $rawContent = $apiResponse.Content
    Write-Host $rawContent
    Write-Host "-------------------------------------------------------"

    # Robust Parsing
    $jsonObj = $rawContent | ConvertFrom-Json
    
    # Try direct access first, then try a regex fallback if the JSON is nested/complex
    #ds-snippet-start:TrustRecords1Step5
    $pdf_path = $jsonObj.pdf_url
    
    if ([string]::IsNullOrWhiteSpace($pdf_path)) {
        # Fallback: Extract using regex if standard JSON object access fails
        if ($rawContent -match '"pdf_url"\s*:\s*"([^"]+)"') {
            $pdf_path = $matches[1]
        }
    }
}
    #ds-snippet-end:TrustRecords1Step5
catch {
    Write-Host "Error fetching trust records: $_" -ForegroundColor Red
    exit
}

if (-not [string]::IsNullOrWhiteSpace($pdf_path)) {
    # Construct Full URL
    $clean_path = $pdf_path.TrimStart('/')
    $full_download_url = "https://api-d.docusign.com/v1/$clean_path"

    Write-Host "SUCCESS: The 'pdf_url' has been found." -ForegroundColor Green
    Write-Host "Full PDF Download URL: $full_download_url"
    Write-Host "-------------------------------------------------------"

    $download_choice = Read-Host "Would you like to download the ID artifact (PDF) now? (y/n)"

    if ($download_choice -match "^[Yy]$") {
        if (-not (Test-Path "proofs")) {
            New-Item -ItemType Directory -Path "proofs" | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $file_path = "proofs/identity_proof_$timestamp.pdf"

        Write-Host "Downloading PDF to $file_path..."
        
        try {
            Invoke-WebRequest -Uri $full_download_url -Headers $headers -OutFile $file_path
            Write-Host "Download complete! PDF saved in the 'proofs' folder." -ForegroundColor Green
        }
        catch {
            Write-Host "Download failed. Check permissions or if the URL has expired." -ForegroundColor Red
        }
    }
}
else {
    Write-Host "Note: API call was successful, but the script could not extract 'pdf_url' from the response." -ForegroundColor Yellow
}

Write-Host "`nDone."
