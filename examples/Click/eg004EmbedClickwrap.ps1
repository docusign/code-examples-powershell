# Step 1. Get required environment variables from .\config\settings.json file
$APIAccountId = Get-Content .\config\API_ACCOUNT_ID

# Check that we have a Clickwrap ID
if (Test-Pasth .\config\CLICKWRAP_ID) {
    $ClickWrapId = Get-Content .\config\CLICKWRAP_ID
} else {
    Write-Output "PROBLEM: A Clickwrap ID is needed. Fix: execute step 1 - Create Clickwrap..."
    exit
}

Write-Output ""
Write-Output "To embed this clickwrap in your website or application, share this code with your developer:"

Write-Output ""
Write-Output '<div id="ds-clickwrap"></div>'
Write-Output '<script src="https://demo.docusign.net/clickapi/sdk/latest/docusign-click.js"></script>'
Write-Output "<script>docuSignClick.Clickwrap.render({"
Write-Output "      environment: 'https://demo.docusign.net',"
Write-Output "      accountId: '$APIAccountId',"
Write-Output "      clickwrapId: '$ClickWrapId',"
Write-Output "      clientUserId: 'UNIQUE_USER_ID'"
Write-Output "    }, '#ds-clickwrap');</script>"
