# Step 1. Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt
$accountId = Get-Content .\config\API_ACCOUNT_ID

# Step 2. Construct your API headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")

$beginDate = Read-Host "Please enter the start date as YYYY-MM-DD: "
$endDate = Read-Host "Please enter the end date as YYYY-MM-DD: "

# You must provide an access token that impersonates a user with permissions to access the Monitor API endpoint
if (($accessToken -eq "") -or ($null -eq $accessToken)) {
   Write-Output "You must provide an access token"
}

# Step 3 start
# Filter parameters
$body = @"
{
  "filters": [
    {
      "FilterName": "Time",
      "BeginTime": "$beginDate",
      "EndTime": "$endDate"
    },
    {
      "FilterName": "Has",
      "ColumnName": "AccountId",
      "Value": "$accountId"
    }
  ],
  "aggregations": [
    {
      "aggregationName": "Raw",
      "limit": "100",
      "orderby": [
        "Timestamp, desc"
      ]
    }
  ]
}
"@
# Step 3 end

# a) Make a POST call to the postWebQuery endpoint to query the companies data.
# b) Display the JSON structure of the created envelope
# Step 4 start
$uri = "https://lens-d.docusign.net/api/v2.0/datasets/monitor/web_query"
try {
	Write-Output "Response:"
	$result = Invoke-WebRequest -uri $uri -headers $headers -body $body -method POST
	$result.content
}
catch {
	$int = 0
  foreach($header in $_.Exception.Response.Headers) {
    if ($header -eq "X-DocuSign-TraceToken") {
      Write-Output "TraceToken : " $_.Exception.Response.Headers[$int]
    }
    $int++
  }
  Write-Output "Error : "$_.ErrorDetails.Message
  Write-Output "Command : "$_.InvocationInfo.Line
}
# Step 4 end

Write-Output ""
Write-Output ""
Write-Output "Done."
Write-Output ""
