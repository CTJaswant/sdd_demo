# Read the hook payload (JSON) that Claude Code sends on stdin.
$raw = [Console]::In.ReadToEnd()
$raw | Out-File -FilePath "$PSScriptRoot\hook-debug.log" -Encoding utf8

$payload = $raw | ConvertFrom-Json
$path = $payload.tool_input.file_path

# Block any edit to appsettings.json.
if ($path -like "*appsettings.json") {
    [Console]::Error.WriteLine("BLOCKED: appsettings.json is protected — edit it manually.")
    exit 2
}

exit 0