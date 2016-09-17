$ErrorActionPreference = 'Stop';

function Get-Configuration {
    Get-Content -Raw -Path (Resolve-Path "$PSScriptRoot\..\Configuration.json") | ConvertFrom-Json
}