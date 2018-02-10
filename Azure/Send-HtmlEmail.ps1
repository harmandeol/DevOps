$ErrorActionPreference = 'Stop';
. "$PSScriptRoot\..\Get-Configuration.ps1"
function Send-HtmlEmail {
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [string] $To,

        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [string] $Subject,

        [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [string] $TemplatePath,

        [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [PSObject] $Data
    )

    $Html=[IO.File]::ReadAllText($TemplatePath)

    $Configuration = Get-Configuration

    if($Data -ne $Null){
        $Data.PSObject.Properties | ForEach-Object {
            $Name = $_.Name
            $Html = $Html -Replace "{{$Name}}", $_.Value
        }
    }

    $Configuration.PSObject.Properties | ForEach-Object {
        $Name = $_.Name
        $Html = $Html -Replace "{{$Name}}", $_.Value
    }

    Send-MailMessage -Subject  $Subject `
                     -From $Configuration.Smtp.From `
                     -To $To `
                     -SmtpServer $Configuration.Smtp.Server `
                     -Body $Html `
                     -BodyAsHtml
}