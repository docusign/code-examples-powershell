param (
    [string]$triggerUrl
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
<!--
#ds-snippet-start:eSign44Step6
-->
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
    <div>
        <iframe src='$triggerUrl' width='800' height='600'></iframe>
    </div>
</body>
</html>

<p><a href="#" onclick="window.close(); return false;">Continue</a></p>
<!--
#ds-snippet-end:eSign44Step6
-->
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