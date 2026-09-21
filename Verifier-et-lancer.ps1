# À exécuter dans une fenêtre PowerShell normale, hors environnement restreint.
[CmdletBinding()]
param(
    [string]$SdkPath = (Join-Path $PSScriptRoot '..\..\work\f'),
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'config\supabase.local.json'),
    [switch]$VerificationSeulement
)
$ErrorActionPreference = 'Stop'
$taskDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$sdkDirectory = [IO.Path]::GetFullPath($SdkPath)
$flutterCommand = Join-Path $sdkDirectory 'bin\flutter.bat'
if (!(Test-Path -LiteralPath $ConfigPath)) {
    throw 'Configuration locale absente. Copier config/supabase.example.json vers config/supabase.local.json et renseigner les valeurs publiques.'
}
$configFile = (Resolve-Path -LiteralPath $ConfigPath).Path
if (!(Test-Path -LiteralPath $flutterCommand)) {
    throw "SDK Flutter absent : fournissez son dossier avec -SdkPath."
}
$bundledGit = 'C:\Users\HPI\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd'
if (Test-Path -LiteralPath (Join-Path $bundledGit 'git.exe')) {
    $env:PATH = "$bundledGit;$env:PATH"
}
$env:PUB_CACHE = Join-Path $taskDirectory 'work\pub-cache'
$env:APPDATA = Join-Path $taskDirectory 'work\appdata'
$env:CI = 'true'
$env:PUB_HOSTED_URL = 'https://pub.dev'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.googleapis.com'
$logDirectory = Join-Path $PSScriptRoot 'verification'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
function Invoke-FlutterCheck {
    param([string]$Name, [string[]]$FlutterArguments)
    $logFile = Join-Path $logDirectory "$Name-$runStamp.log"
    "Commande : flutter $($FlutterArguments -join ' ')`nDate : $(Get-Date -Format o)" |
        Set-Content -LiteralPath $logFile -Encoding utf8
    $previousErrorPreference = $ErrorActionPreference
    try {
        # PowerShell 5 ne doit pas interrompre la capture au premier stderr natif.
        $ErrorActionPreference = 'Continue'
        & $flutterCommand @FlutterArguments 2>&1 | ForEach-Object {
            $line = $_.ToString()
            Add-Content -LiteralPath $logFile -Value $line -Encoding utf8
            Write-Output $line
        }
        $checkExit = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorPreference
    }
    "Code de sortie : $checkExit" | Add-Content -LiteralPath $logFile -Encoding utf8
    if ($checkExit -ne 0) { throw "Échec de $Name. Journal : $logFile" }
}
Push-Location $PSScriptRoot
try {
    Invoke-FlutterCheck 'flutter-pub-get' @('pub', 'get')
    Invoke-FlutterCheck 'flutter-analyze' @('analyze')
    Invoke-FlutterCheck 'flutter-test' @('test', '--reporter', 'expanded', "--dart-define-from-file=$configFile")
    if (!$VerificationSeulement) {
        & $flutterCommand run -d edge --web-port 8765 "--dart-define-from-file=$configFile"
        if ($LASTEXITCODE -ne 0) { throw 'Lancement Web en échec.' }
    }
} finally {
    Pop-Location
}
