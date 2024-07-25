function Invoke-Script {
    param (
        [string]$Command
    )

    # Get the path to the PowerShell executable
    $powershellPath = if ($IsWindows) {
        try {
            (Get-Command powershell.exe -ErrorAction Stop).Source
        } catch {
            "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        }
    } else {
        try {
            (Get-Command pwsh -ErrorAction Stop).Source
        } catch {
            "/usr/local/bin/pwsh"
        }
    }

    $powershellPath = $powershellPath -replace ' ', '` ' # add ` if the path has spaces

    # Execute the script using the appropriate PowerShell executable
    $fullCommand = "$powershellPath -File $Command"

    # Execute the command
    Invoke-Expression $fullCommand
}
