# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
# Step 2 start
$headers1 = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers1.add("Authorization","Bearer ${accessToken}")
$headers1.add("Content-Disposition", "filename=bulkimport.csv")
$headers1.add("Content-Type","text/csv")

$headers2 = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers2.add("Authorization","Bearer ${accessToken}")
# Step end

# Get required environment variables from .\config\settings.json file
$variables = Get-Content .\config\settings.json -Raw | ConvertFrom-Json

# Check that we have an organization id in the settings.json config file
if (!$variables.ORGANIZATION_ID) {
    Write-Output "Organization ID is needed. Please add the ORGANIZATION_ID variable to the settings.json"
    exit -1
}

$base_path = "https://api-d.docusign.net/management"
$organizationId = $variables.ORGANIZATION_ID

# Create the bulk import request
# Step 3 start
$body = @"
AccountID,AccountName,FirstName,LastName,UserEmail,eSignPermissionProfile,Group,Language,UserTitle,CompanyName,AddressLine1,AddressLine2,City,StateRegionProvince,PostalCode,Phone,LoginPolicy,AutoActivate
$accountId,Sample Account,John,Markson,user1email@example.com,Account Administrator,Everyone,en,Mr.,Some Division,123 4th St,Suite C1,Seattle,WA,8178,2065559999,fedAuthRequired,true
$accountId,Sample Account,Jill,Smith,user2email@example.com,Account Administrator,Everyone,en,Mr.,Some Division,123 4th St,Suite C1,Seattle,WA,8178,2065559999,fedAuthRequired,true
$accountId,Sample Account,James,Grayson,user3emailt@example.com,Account Administrator,Everyone,en,Mr.,Some Division,123 4th St,Suite C1,Seattle,WA,8178,2065559999,fedAuthRequired,true
"@

$uri1 = "${base_path}/v2/organizations/$organizationId/imports/bulk_users/add"
$result1 = Invoke-WebRequest -headers $headers1 -Uri $uri1 -body $body -Method POST
$result1.Content
$results = $result1 | ConvertFrom-Json
$importId = $results.id
# Step 3 end

# Check the request status
Write-Output "Sleep 20 seconds..."
Start-Sleep 20
# Step 4 start
$uri2 = "${base_path}/v2/organizations/$organizationId/imports/bulk_users/$importId"
$result2 = Invoke-WebRequest -headers $headers2 -Uri $uri2 -Method GET
$result2.Content
# Step 4 end
