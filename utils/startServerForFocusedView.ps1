param(
  [Parameter(Mandatory = $true)]
  [string]$signingURL
  )

$port = '8080'
$ip = 'localhost'

# Get required environment variables from ..\config\settings.json file
$configFile = ".\config\settings.json"
$config = Get-Content $configFile -Raw | ConvertFrom-Json
$integrationKey  = $config.INTEGRATION_KEY_AUTH_CODE

$socket = 'http://' + $ip + ':' + $port + '/'

$responseOk = @"
<!--
#ds-snippet-start:eSign44Step6
-->
<br />
<h2>The document has been embedded with focused view.</h2>
<br />
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Signing</title>
    <style>
        html,
        body {
            padding: 0;
            margin: 0;
            font: 13px Helvetica, Arial, sans-serif;
        }
        .docusign-agreement {
            width: 75%;
            height: 800px;
        }
    </style>
</head>
<body>
    <div class="docusign-agreement" id="agreement"></div>
</body>
</html>
<p><a>Continue</a></p>
<script src='https://js.docusign.com/bundle.js'></script>
<script>
    window.DocuSign.loadDocuSign('$integrationKey')
    .then((docusign) => {
      const signing = docusign.signing({
                url: '$signingURL',
                displayFormat: 'focused',
                style: {
                    /** High-level variables that mirror our existing branding APIs. Reusing the branding name here for familiarity. */
                    branding: {
                        primaryButton: {
                            /** Background color of primary button */
                            backgroundColor: '#333',
                            /** Text color of primary button */
                            color: '#fff',
                        }
                    },
                    /** High-level components we allow specific overrides for */
                    signingNavigationButton: {
                        finishText: 'You have finished the document! Hooray!',
                        position: 'bottom-center'
                    }
                }
            });

            signing.on('ready', (event) => {
              console.log('UI is rendered');
          });
      
          signing.on('sessionEnd', (event) => {
              /** The event here denotes what caused the sessionEnd to trigger, such as signing_complete, ttl_expired etc../ **/
              console.log('sessionend', event);
              window.close();
          });
      
          signing.mount('#agreement');
      })
      .catch((ex) => {
          // Any configuration or API limits will be caught here
      });
</script>

<!--
#ds-snippet-end:eSign44Step6
-->
"@

[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($socket)
$listener.Start()
Start-Process $socket

$context = $listener.GetContext()
$response = $context.Response

$buffer = [System.Text.Encoding]::UTF8.GetBytes($responseOk)
$response.ContentType = "text/html"
$response.ContentLength64 = $buffer.Length
$output = $response.OutputStream
$output.Write($buffer, 0, $buffer.Length)
$output.Close()
