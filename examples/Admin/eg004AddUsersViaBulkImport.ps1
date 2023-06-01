# Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Construct your API headers
#ds-snippet-start:Admin4Step2
$headers1 = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers1.add("Authorization","Bearer ${accessToken}")
$headers1.add("Content-Disposition", "filename=bulkimport.csv")
$headers1.add("Content-Type","text/csv")

$headers2 = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers2.add("Authorization","Bearer ${accessToken}")
#ds-snippet-end:Admin4Step2

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
#ds-snippet-start:Admin4Step3
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
#ds-snippet-end:Admin4Step3

# Check the request status
Write-Output "Sleep 20 seconds..."
Start-Sleep 20
#ds-snippet-start:Admin4Step4
$uri2 = "${base_path}/v2/organizations/$organizationId/imports/bulk_users/$importId"
$result2 = Invoke-WebRequest -headers $headers2 -Uri $uri2 -Method GET
$result2.Content
#ds-snippet-end:Admin4Step4
