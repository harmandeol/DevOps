$ErrorActionPreference = 'Stop';

function Get-Configuration {
    $configuration = Get-Content -Raw -Path (Resolve-Path "$PSScriptRoot\..\Configuration.json") | ConvertFrom-Json
    if ($env:AppSettings:AzureBlobStorageConnection) {
        $configuration.AzureBlobStorageConnection = $env:AppSettings:AzureBlobStorageConnection
    }
    if ($env:SQLAZURECONNSTR_DefaultConnection) {
        $configuration.DefaultConnection = $env:ASQLAZURECONNSTR_DefaultConnection
    }
    return $configuration
}