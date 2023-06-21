# Temp files:
$response = New-TemporaryFile

# Step 1. Get required environment variables from .\config\settings.json file
$accessToken = Get-Content .\config\ds_access_token.txt

# Step 2. Construct your API headers
#ds-snippet-start:Monitor1Step2
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("Authorization", "Bearer $accessToken")
$headers.add("Accept", "application/json")
$headers.add("Content-Type", "application/json")
#ds-snippet-end:Monitor1Step2

# Declare variables
$complete=$false
$cursorValue=""
$iterations=0
# You must provide an access token that impersonates a user with permissions to access the Monitor API endpoint
if (($accessToken -eq "") -or ($null -eq $accessToken)) {
   Write-Output "You must provide an access token"
   $complete = $true
}

# Step 3: Get monitoring data
# First call the endpoint with no cursor to get the first records.
# After each call, save the cursor and use it to make the next
# call from the point where the previous one left off when iterating through
# the monitoring records
#ds-snippet-start:Monitor1Step3
DO {
   $iterations++
   Write-Output ""
   try {
      Invoke-RestMethod `
      -Uri "https://lens-d.docusign.net/api/v2.0/datasets/monitor/stream?cursor=${cursorValue}&limit=2000" `
      -Method 'GET' `
      -Headers @{
         'Authorization' = "Bearer $accessToken";
         'Content-Type'  = "application/json";
      } `
      -OutFile $response
      # Display the data
      Write-Output "Iteration:"
      Write-Output $iterations
      Write-Output "Results:"
      Get-Content $response
      # Get the endCursor value from the response. This lets you resume
      # getting records from the spot where this call left off
      $endCursorValue = (Get-Content $response | ConvertFrom-Json).endCursor
      Write-Output "endCursorValue is:"
      Write-Output $endCursorValue
      Write-Output "cursorValue is:"
      Write-Output $cursorValue

      # If the endCursor from the response is the same as the one that you already have,
      # it means that you have reached the
      # end of the records
      if ($endCursorValue -eq $cursorValue) {
        Write-Output 'After getting records, the cursor values are the same. This indicates that you have reached the end of your available records.'
        $complete=$true
      }
      else {
        Write-Output "Updating the cursor value of $cursorValue to the new value of $endCursorValue"
        $cursorValue=$endCursorValue
        Start-Sleep -Second 5
      }
   }
   catch {
      $int = 0
      foreach($header in $_.Exception.Response.Headers) {
        if ($header -eq "X-DocuSign-TraceToken") {
          Write-Output "TraceToken : " $_.Exception.Response.Headers[$int]
	}
        $int++
      }
      Write-Output "You do not have Monitor enabled for your account, follow https://developers.docusign.com/docs/monitor-api/how-to/enable-monitor/ to get it enabled."
      Write-Output "Command : "$_.InvocationInfo.Line
      $complete = $true
   }

} While ($complete -eq $false )
#ds-snippet-end:Monitor1Step3

Remove-Item $response

Write-Output ""
Write-Output ""
Write-Output "Done."
Write-Output ""
