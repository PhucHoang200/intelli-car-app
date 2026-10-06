param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TestArguments
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw 'Python is required. Install Python or add it to PATH.'
}
& python -u (Join-Path $PSScriptRoot 'run_tests.py') @TestArguments
exit $LASTEXITCODE
