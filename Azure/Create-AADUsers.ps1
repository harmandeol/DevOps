$ErrorActionPreference = 'Stop';
. "$PSScriptRoot\Send-HtmlEmail.ps1"

function Create-AADUsers {
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [string] $CsvFilePath = "data\" + $MyInvocation.MyCommand.Name + ".csv"
    )

    Write-Host ('Importing Users from path: {0}' -f $CsvFilePath);

    $usersList  =   Import-Csv $CsvFilePath

    $usersList | foreach {
        $User = Get-MsolUser -UserPrincipalName $email -ErrorAction SilentlyContinue
        if($User -eq $Null) {
            Write-Host "Creating User n Azure AD: $_"

            $displayName = $_.FirstName + ' ' + $_.LastName

            $user = New-MsolUser -UserPrincipalName $_.Email `
                        -DisplayName  $displayName `
                        -FirstName $_.FirstName `
                        -LastName $_.LastName `
                        -ForceChangePassword $true `
                        -PasswordNeverExpires $false `
                        -UsageLocation 'AU' `
                        -AlternateEmailAddresses $_.AlternateEmail

            Add-MsolRoleMember -RoleName $_.Role -RoleMemberEmailAddress $_.Email

            $_ | add-member -membertype noteproperty -name Password -value $user.Password

            $scriptName = $MyInvocation.MyCommand.Name
            Send-HtmlEmail -To $_.AlternateEmail -Subject "Your Azure AD Account is created!" -Data $_ -TemplatePath "$PSScriptRoot\templates\$scriptName.htm"
        } else {
            Write-Host "User already created: $User"
        }
    }


    Write-Host "Done"

    Move-Item $CsvFilePath (Join-Path ($CsvFilePath | Split-Path) "processed" )
}