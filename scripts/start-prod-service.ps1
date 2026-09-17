[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$projectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$supervisorScript = Join-Path $projectDir "scripts\prod-supervisor.mjs"

function Get-SupervisorProcess {
    Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
        Where-Object { $_.CommandLine -and $_.CommandLine -match [regex]::Escape($supervisorScript) }
}

$existing = @(Get-SupervisorProcess)
if ($existing.Count -gt 0) {
    Write-Host "Production supervisor is already running. PID: $($existing[0].ProcessId)"
    exit 0
}

$node = Get-Command node.exe -ErrorAction Stop
Write-Host "Starting feishu-mcp production service..."
$launcher = Start-Process -FilePath $node.Source `
    -ArgumentList @($supervisorScript) `
    -WorkingDirectory $projectDir `
    -WindowStyle Hidden `
    -PassThru

Start-Sleep -Seconds 3
$started = @(Get-SupervisorProcess)
if ($started.Count -eq 0) {
    throw "Production supervisor did not start. Check $projectDir\logs\prod-supervisor.log"
}

Write-Host "Production supervisor started. PID: $($started[0].ProcessId)"
