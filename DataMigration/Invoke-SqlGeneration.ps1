$ErrorActionPreference = 'Stop';
. "$PSScriptRoot\..\Common\GzipModule.ps1"
. "$PSScriptRoot\..\Common\Get-Configuration.ps1"
. "$PSScriptRoot\Get-SqlCommandsFromSuppliers.ps1"


function Invoke-SqlGeneration {

    $Configuration = Get-Configuration
    $localDataDirectory = "$PSScriptRoot\Data"
    New-Item -ItemType Directory -Force -Path $localDataDirectory

    $ctx = New-AzureStorageContext -ConnectionString $Configuration.AzureBlobStorageConnection
    $ctx | Get-AzureStorageBlob -Container $Configuration.ContainerName | ForEach-Object {`
        $ctx | Get-AzureStorageBlobContent -Container $Configuration.ContainerName -Blob $_.Name -Destination $localDataDirectory -Force `
    }

    Invoke-SqlCoverter -FilePrefix "suppliers"

    Get-ChildItem -Path $localDataDirectory -Filter "*.sql" -File | Set-AzureStorageBlobContent -Container $Configuration.ContainerName  -Context $ctx -Force

}

function Invoke-SqlCoverter([string] $FilePrefix){
    Get-GzipContent -FilePath  (Join-Path -Path $localDataDirectory -ChildPath "$FilePrefix.txt.gz") `
    | ConvertFrom-Json | Get-SqlCommandsFromSuppliers ` | Out-File -FilePath  (Join-Path -Path $localDataDirectory -ChildPath "$FilePrefix.sql")
}

Invoke-SqlGeneration