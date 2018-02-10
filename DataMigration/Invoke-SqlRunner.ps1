$ErrorActionPreference = 'Stop';
. "$PSScriptRoot\..\Common\Get-Configuration.ps1"

function Invoke-SqlRunner {

    Invoke-SqlCmdForCCE -InputFile "suppliers.sql"
}

function Invoke-SqlCmdForCCE ([string] $InputFile) {
    $localDataDirectory = "$PSScriptRoot\Data"
    $Configuration = Get-Configuration
    Invoke-Sqlcmd -ConnectionString $Configuration.DefaultConnection `
        -InputFile (Join-Path -Path $localDataDirectory -ChildPath $InputFile)`
        -OutputSqlErrors $True `
        -Verbose
}

Invoke-SqlRunner