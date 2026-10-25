# Build / upload / monitor the RX or TX firmware with the pinned sketch profiles (sketch.yaml).
#   .\tools\fw.ps1 rx                     compile only
#   .\tools\fw.ps1 tx -Upload -Port COM7  compile, then flash
#   .\tools\fw.ps1 rx -Monitor -Port COM7 serial console (115200) after the other steps
# Build output stays in %LOCALAPPDATA%\bremote-build\<target>, so rebuilds are incremental.
param(
    [Parameter(Mandatory = $true, Position = 0)][ValidateSet("rx", "tx")][string]$Target,
    [switch]$Upload,
    [switch]$Monitor,
    [string]$Port
)
$ErrorActionPreference = "Stop"

$cli = (Get-Command arduino-cli -ErrorAction SilentlyContinue).Source
if (-not $cli) { $cli = Join-Path $env:LOCALAPPDATA "Programs\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe" }
if (-not (Test-Path $cli)) { throw "arduino-cli not found (PATH or Arduino IDE bundle)" }

$sketch = Join-Path $PSScriptRoot ("..\Source\V2_Integration_" + $(if ($Target -eq "rx") { "Rx" } else { "Tx" }))
$build = Join-Path $env:LOCALAPPDATA "bremote-build\$Target"

& $cli compile --profile $Target --build-path $build $sketch
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (($Upload -or $Monitor) -and -not $Port) {
    & $cli board list
    throw "Pass -Port COMx (see the list above)"
}
if ($Upload) {
    & $cli upload --profile $Target --port $Port --input-dir $build $sketch
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
if ($Monitor) {
    & $cli monitor --port $Port --config baudrate=115200
}
