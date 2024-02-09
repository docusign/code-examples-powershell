param(
  [Parameter(Mandatory = $true)]
  [string]$integrationKey,
  [Parameter(Mandatory = $true)]
  [string]$url,
  [Parameter(Mandatory = $true)]
  [string]$instanceToken
  )

$port = '8080'
$ip = 'localhost'

$socket = 'http://' + $ip + ':' + $port + '/'

$responseOk = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" />
</head>

<body>
<div id="app">
  <div id="webform-customer-app-area">
    <h1 id="webforms-heading">Embedded Web Form Example</h1>
    <div id="docusign" class="webform-iframe-container">
      <p>Web Form will render here</p>
    </div>
  </div>
</div>
</body>
</html>

<!--
  #ds-snippet-start:WebForms1Step6
-->
<script src="https://js.docusign.com/bundle.js"></script>
<script>
async function loadWebform() {
const { loadDocuSign } = window.DocuSign
const docusign = await loadDocuSign('$integrationKey');

const webFormOptions = {
// Optional field that can prefill values in the form. This overrides the formValues field in the API request
prefillValues: {},
// Used with the runtime API workflow, for private webforms this is needed to render anything
instanceToken: '$instanceToken',
// Controls whether the progress bar is shown or not
hideProgressBar: false,
// These styles get passed directly to the iframe that is rendered
iframeStyles: {
  minHeight: "1500px",
},
// Controls the auto resize behavior of the iframe
autoResizeHeight: true,
// These values are passed to the iframe URL as query params
tracking: {
  "tracking-field": "tracking-value",
},
//These values are passed to the iframe URL as hash params
hidden: {
  "hidden-field": "hidden-value",
},
};

const webFormWidget = docusign.webforms({
url: '$url',
options: webFormOptions,
});

webFormWidget.mount("#docusign");
}
loadWebform();
</script>
<!--
  #ds-snippet-end:WebForms1Step6
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
