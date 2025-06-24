using namespace System.Net

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [int]
    $Port
)

$VerbosePreference = 'Continue'

$http = [HttpListener]::new()
$http.Prefixes.Add("http://localhost:$Port/")
$http.Start()
Write-Host "Web server started on port localhost:$Port" -ForegroundColor Yellow

while ($http.IsListening) {
    try {
        $context = $http.GetContext()
    }
    catch [HttpListenerException] {
        if (-not $http.IsListening) {
            break
        }

        throw
    }

    Start-ThreadJob -ScriptBlock {
        param ($http, $context)

        Write-Host "Received request: $($context.Request.HttpMethod) $($context.Request.RawUrl)" -ForegroundColor Yellow

        if ($context.Request.HttpMethod -ne 'GET') {
            $context.Response.StatusCode = 405
            $context.Response.OutputStream.Close()
            continue
        }

        if ($context.Request.RawUrl -eq '/shutdown') {
            $context.Response.StatusCode = 200
            $context.Response.OutputStream.Close()
            $http.Stop()
        }
        elseif ($context.Request.RawUrl -eq '/') {
            $context.Response.StatusCode = 200
            $context.Response.OutputStream.Close()
        }
        elseif ($context.Request.RawUrl -match '\/id=(\d+)&delay=(\d+)') {
            $delay = [int]$matches[2]
            Start-Sleep -Seconds $delay

            $respJson = @{
                delay = $delay
            } | ConvertTo-Json -Compress
            $resp = [System.Text.Encoding]::UTF8.GetBytes($respJson)
            $context.Response.ContextLength64 = $resp.Length
            $context.Response.OutputStream.Write($resp, 0, $resp.Length)
            $context.Response.OutputStream.Close()
        }
        else {
            $context.Response.StatusCode = 404
            $context.Response.OutputStream.Close()
        }
    } -ArgumentList $http, $context -StreamingHost $Host | Out-Null
}
