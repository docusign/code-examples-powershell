param (
    [string]$instanceUrl
)

$PORT = 8080
$IP = "localhost"
$listener = New-Object System.Net.HttpListener
$prefix = "http://$IP`:$PORT/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Listening on $prefix"

# Correct HTML without raw HTTP headers
$responseHtml = @"
<br />
<h2>The document has been embedded using Maestro Embedded Workflow.</h2>
<br />

<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8' />
    <title>Example Workflow</title>
    <style>
        html, body {
            padding: 0;
            margin: 0;
            font: 13px Helvetica, Arial, sans-serif;
        }
    </style>
</head>
<body>
<!--
#ds-snippet-start:Maestro1Step6
-->
    <div>
        <iframe src='$instanceUrl' width='800' height='600'></iframe>
    </div>
<!--
#ds-snippet-end:Maestro1Step6
-->
</body>
</html>

<p><a href="#" onclick="window.close(); return false;">Continue</a></p>
"@

try {
    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        if ($request.HttpMethod -eq "GET") {
            $response.ContentType = "text/html"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseHtml)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            break
        }
    }
} catch {
    Write-Error "Server error: $_"
} finally {
    $listener.Stop()
    Write-Host "Server stopped."
}