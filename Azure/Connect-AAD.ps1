$ErrorActionPreference = 'Stop';

function Connect-AAD {

    Import-Module MSOnline

    $credential = Get-Credential

    Connect-MsolService -Credential $credential #-AzureEnvironment ""
}

Connect-AAD